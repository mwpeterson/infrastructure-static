resource "aws_codepipeline" "pipeline" {
  provider = "aws.west2"
  name     = "${var.project}-${var.environment}"
  role_arn = "${data.terraform_remote_state.global.codepipeline_role.arn}"

  artifact_store {
    location = "${data.terraform_remote_state.global.codepipeline_bucket.id}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["${var.project}-${var.environment}"]

      configuration {
        Owner      = "gateway-church"
        Repo       = "${var.project}"
        Branch     = "develop"
        OAuthToken = "${var.github_oauth_token}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["${var.project}-${var.environment}"]
      version         = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.project.name}"
      }
    }
  }
}

resource "aws_codebuild_project" "project" {
  provider      = "aws.west2"
  name          = "${var.project}-${var.environment}"
  build_timeout = "5"
  service_role  = "${data.terraform_remote_state.global.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/eb-ruby-2.2-amazonlinux-64:2.1.6"
    type         = "LINUX_CONTAINER"
  }

  source {
    type = "CODEPIPELINE"

    buildspec = <<BUILDSPEC
version: 0.1

phases: 
  install: 
    commands: 
      - gem install jekyll bundler
      - bundle install
  build: 
    commands: 
      - bundle exec jekyll build
  post_build: 
    commands: 
      - aws s3 sync --delete --cache-control max-age=604800 _site s3://${aws_s3_bucket.bucket.id}
      - aws sns publish --topic-arn ${data.terraform_remote_state.global.codebuild_topic.arn} --subject '${var.project} deployed to ${var.environment}' --message "<a href='https://console.aws.amazon.com/cloudwatch/home?region=$${AWS_REGION}#logStream:group=/aws/codebuild/${var.project}-${var.environment}'>Logs</a>" 
BUILDSPEC
  }

  tags {
    environment = "${var.environment}"
    terraform   = true
  }
}
