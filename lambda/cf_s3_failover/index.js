require('dotenv').load(); // load environment variables
AWS = require('aws-sdk'); // for talking to AWS
var cloudfront = new AWS.CloudFront();
var cloudwatch = new AWS.CloudWatch({ region: 'us-east-1' });

exports.handler = function(event, context, callback) {
    context.callbackWaitsForEmptyEventLoop = false; 
    var message = JSON.parse(event.Records[0].Sns.Message);
    // possible states: "OK", "ALARM", "INSUFFICIENT_DATA"
    var state = message.NewStateValue;
    // data is JSON encoded in AlarmDescription
    // Terraform can write to this field during provisioning
    // and avoid the need for service discovery
    // Yes, it's a hack
    var alarm = JSON.parse(message.AlarmDescription);
    var cloudfront_id = alarm.cloudfront_id; // cloudfront distribution id
    var this_bucket = alarm.replica ? alarm.replica_id : alarm.bucket_id; // find current bucket by value of replica
    var other_bucket = alarm.replica ? alarm.bucket_id : alarm.replica_id; // find the other bucket by value of replica
    // code logic:
    //  get cloudfront config
    //  if state is ALARM
    //      if cloudront is using this bucket
    //          if other bucket is health
    //              update cloudfront with other bucket
    //  else if state is OK
    //      if !replica
    //          if cloudfront is not using bucket
    //              update cloudfront with this bucket
    //  else ignore insufficient_data state
    cloudfront.getDistributionConfig({
        Id: alarm.cloudfront_id
    }, updateDistribution);
	
    function updateDistribution (err, data) {
	if (err) {
	    console.error(err, err.stack);
	    callback(err.stack);
	    return;
	}
	var current_origin = data.DefaultCacheBehavior.TargetOriginId;
	console.log(state,current_origin,this_bucket,alarm.replica);
	switch(state)
	{
	    case "ALARM":
		console.log('case ALARM');
		if ( data.DefaultCacheBehavior.TargetOriginId == this_bucket ) {
		    console.log("if this_bucket: " + this_bucket);
		    cloudwatch.describeAlarms({
			AlarmNames: [ "healthcheck-" + other_bucket + "-alarm" ]
		    }, function(err,check) {
			console.log("err: " + JSON.stringify(err));
			console.log("check: " + JSON.stringify(check));
			if (err) {
			    console.error(err, err.stack);
			    callback(err.stack);
			    return;
			}
			if ( check.MetricAlarms[0].StateValue == 'OK' ) {
			    data.DefaultCacheBehavior.TargetOriginId = other_bucket;
			    data.IfMatch = data.ETag;
			    delete data.ETag;
			    cloudfront.updateDistributionConfig({
				Id: alarm.cloudfront_id,
				DistributionConfig: data
			    }, function(err,data) {
				if (err) {
				    console.error(err, err.stack);
				    callback(err.stack);
				    return;
				}
				console.log(
				    data.Distribution.Id,
				    data.Distribution.Status,
				    data.Distribution.LastModifiedTime
				);
				callback(null);
				return;
			    });
			} else {
			    console.log(other_bucket + " is " + check.MetricAlarms[0].StateValue);
			}
			callback(null);
			return;
		    });
		    console.log('end if');
		    callback(null);
		    return;
		}
		console.log('end case ALARM');
		break;
	    case "OK":
		if ( ! alarm.replica ) {
		    if ( data.DefaultCacheBehavior.TargetOriginId != this_bucket ) {
			data.DefaultCacheBehavior.TargetOriginId = this_bucket;
			data.IfMatch = data.ETag;
			delete data.ETag;
			cloudfront.updateDistributionConfig({
			    Id: alarm.cloudfront_id,
			    DistributionConfig: data
			}, function(err,data) {
			    if (err) {
				console.error(err, err.stack);
				callback(err.stack);
				return;
			    }
			    console.log(
				data.Distribution.Id,
				data.Distribution.Status,
				data.Distribution.LastModifiedTime
			    );
			    callback(null);
			    return;
			});
		    }
		}	
		break;
	    default:
		// ignore INSUFFICIENT_DATA state
	}
	callback(null);
	return;
    }; 
};
