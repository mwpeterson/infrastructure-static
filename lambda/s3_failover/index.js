require('dotenv').load(); // load environment variables

exports.handler = function(event, context, callback) {
    context.callbackWaitsForEmptyEventLoop = false; 
    callback(null);
    return;
};
