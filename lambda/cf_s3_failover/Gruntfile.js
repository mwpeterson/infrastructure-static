module.exports = function(grunt) {
  grunt.registerTask('run', ['lambda_invoke']);
  grunt.registerTask('build', ['lambda_package:default']);
  grunt.registerTask('deploy', ['build', 'lambda_deploy:default']);
  grunt.loadNpmTasks('grunt-aws-lambda');
  grunt.initConfig({
    lambda_invoke: {
      default: {
      }
    },
    lambda_package: {
      default: {
        options: {
          include_files: ['.env'],
          include_time: false,
          include_version: false,
        }
      }
    },
    lambda_deploy: {
      default: {
        options: {
          region: "us-west-2",
        },
        arn: 'arn:aws:lambda:us-west-2:177193921434:function:cf_s3_failover'
      }
    }
  });
};
