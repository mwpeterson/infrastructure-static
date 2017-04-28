# SNS2SLACK-CODEBUILD

SNS notifications to Slack when Codebuild deploys

## SETUP

sns2slack-codebuild configuration is handled by Terraform in https://github.com/gateway-church/infrastructure-static

## INSTALLATION

1. Clone the repository at https://github.com/gateway-church/sns2slack-codebuild
2. Install the dependencies:
    - `npm install`
3. Ensure your `~/.aws/credentials` file is configured. Use your own. Ask your
AWS administrator if you need help.

## TESTING

`grunt run`

You can edit `event.json` to change the parameters sent to Failover and
test different parts of the code:

```json
{
    "grunt": true,
    "Records": [{
        "EventSource": "aws:sns",
        "EventVersion": "1.0",
        "EventSubscriptionArn": "arn:aws:sns:us-west-2:177193921434:codebuild-topic:2f93970c-f759-4b49-91ba-8462d9fba5d9",
        "Sns": {
            "Type": "Notification",
            "MessageId": "b1d7cd0e-c1de-5665-b6f4-9c6c9fb1a6b5",
            "TopicArn": "arn:aws:sns:us-west-2:177193921434:codebuild-topic",
            "Subject": "testproject-static deployed to test",
            "Message": "<https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#logStream:group=/aws/codebuild/testproject-static-stage|view logs>",
            "Timestamp": "2017-04-08T03:42:39.995Z",
            "SignatureVersion": "1",
            "Signature": "CU7UOI7vEQmfrM8Q2mhOwSlV6P4kW+FmT9eFO72rGXOg2PWC1x+EFQFZw/RS29h18zFwVYpbA96M+u4+YkH/ty5kA7fZhQ1yIJo2xEe5RQbu2a8qIRgHHJKihWsnOLZctZf6PJi2KjFRECmXLjQhqTYiuasyqFesb9ZLtnVeljYyMJf0ValGx2Z3pqPQgFYQge0p7ESBxDpz+1+cAL9Fa2BxlS97Wnj15r1DUt2dL688aZKu/QSNZPdHnlTN//toLDQTOagxdmzZrdoRqDi6RD6LgEpfiV0MWwV23HsQ68Taf34QEK7dHNh6jNeV7GF8KH+SakEDQTBcOllNuTJK7A==",
            "SigningCertUrl": "https://sns.us-west-2.amazonaws.com/SimpleNotificationService-b95095beb82e8f6a046b3aafc7f4149a.pem",
            "UnsubscribeUrl": "https://sns.us-west-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-west-2:177193921434:codebuild-topic:2f93970c-f759-4b49-91ba-8462d9fba5d9",
            "MessageAttributes": {}
        }
    }]
}
```

- `grunt: true` disables posting responses to Slack's #emergency channel

## DEPLOYMENT

`grunt deploy` is an alias for `grunt lambda_package lambda_deploy`