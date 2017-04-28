require('dotenv').load(); // load environment variables
AWS = require('aws-sdk'); // for talking to AWS
var cloudfront = new AWS.CloudFront();

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
    var replica = alarm.replica; // true if replica bucket
    var bucket_id = alarm.bucket_id; // id of master bucket
    var replica_id = alarm.replica_id; // id of replica bucket 
	var this_bucket = replica ? replica_id : bucket_id;
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
    }, function(err, data) {
        if (err) {
            console.error(err, err.stack);
            callback(err.stack);
            return;
        }
		var current_origin = data.DefaultCacheBehavior.TargetOriginId;
		switch(state)
		{
		case "ALARM":
			if ( current_origin == this_bucket ) {
				console.log("updating");
			}
			break;
		case "OK":
			if ( ! replica ) {
				if ( current_origin != this_bucket ) {
					console.log("updating");
				}
			}	
			break;
		default:
        }
        callback(null);
        return;
    }); 
};
