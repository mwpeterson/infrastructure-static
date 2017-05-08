require('dotenv').load(); // load environment variables
AWS = require('aws-sdk'); // for talking to AWS
var cloudfront = new AWS.CloudFront();
var cloudwatch = new AWS.CloudWatch({ region: 'us-east-1' });

exports.handler = function(event, context, callback) {

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
  
  var done;

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


 var cf_config = cloudfront.getDistributionConfig({
    Id: alarm.cloudfront_id
  }).promise();
  cf_config.then(updateConfig,processErr)
    .catch(processErr)
    .then(function(err) {
      callback(err);
    });

  function updateConfig(config) {
	var current_origin = config.DistributionConfig.DefaultCacheBehavior.TargetOriginId;
	switch(state)
	{
      case "ALARM":
        if ( current_origin == this_bucket ) {
          // check Cloudwatch
          var checkBucket = cloudwatch.describeAlarms({
			AlarmNames: [ "healthcheck-" + other_bucket + "-alarm" ]
          }).promise();
          checkBucket.then(function(check) {
			if ( check.MetricAlarms[0].StateValue == 'OK' ) {
              // since this_bucket is in ALARM and cloudfront is this_bucket, switch to other_bucket
              var update = updateCloudfront(alarm.cloudfront_id, config, other_bucket);
              update.then(logUpdate);
            }
          });
		}
		break;
      case "OK":
        if ( ! alarm.replica ) { // ignore if replica triggered OK
          if ( current_origin != this_bucket ) {
          // since this_bucket is in OK and cloudfront isn't this_bucket, switch to this_bucket
            var update = updateCloudfront(alarm.cloudfront_id, config, this_bucket);
            update.then(logUpdate);
          }
        }
        break;
      default:
		// ignore INSUFFICIENT_DATA state
	}
  };

  function updateCloudfront(id, params, bucket) {
    params.DistributionConfig.DefaultCacheBehavior.TargetOriginId = bucket;
    params.Id = id;
    params.IfMatch = params.ETag;
    delete params.ETag;
    return cloudfront.updateDistribution(params).promise();
  }

  function logUpdate(data) {
    console.log(data);
  };

  function processErr(err) {
    console.error(err);
    return err;
  };


};
