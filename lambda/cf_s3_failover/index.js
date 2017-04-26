require('dotenv').load(); // load environment variables

exports.handler = function(event, context, callback) {
    context.callbackWaitsForEmptyEventLoop = false; 
    console.log(JSON.stringify(event,null,2));
    callback(null);
    return;
};
