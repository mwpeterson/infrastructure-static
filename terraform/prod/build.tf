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
        Branch     = "master"
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

  provisioner "local-exec" {
    command = "aws codepipeline start-pipeline-execution --name ${aws_codepipeline.pipeline.name}"
  }
}

resource "aws_codebuild_project" "project" {
  provider      = "aws.west2"
  name          = "${var.project}-${var.environment}"
  build_timeout = "5"
  service_role  = "${data.terraform_remote_state.global.codebuild_role.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/eb-ruby-2.2-amazonlinux-64:2.1.6"
    type         = "LINUX_CONTAINER"
  }

  source {
    type     = "GITHUB"
    location = "${var.github_project_url}"

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
      - aws s3 sync --cache-control max-age=604800 --exclude 'buildspec.yml' --exclude 'sample.json' --exclude '*terraform.tfvars*' --exclude 'infrastructure/*' _site s3://${aws_s3_bucket.bucket.id} --delete 
s3://testproject-static-prod --delete
BUILDSPEC

    auth = {
      type = "OAUTH"
    }
  }

  tags {
    environment = "${var.environment}"
    project     = "${var.project}"
    terraform   = true
  }
}
