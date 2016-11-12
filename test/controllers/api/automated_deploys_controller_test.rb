# frozen_string_literal: true
require_relative '../../test_helper'

SingleCov.covered!

describe Api::AutomatedDeploysController do
  def post_create
    post :create, params: {project_id: :foo, deploy_group: 'pod100', env: {'FOO' => 'bar'}}, format: :json
  end

  oauth_setup!

  describe "#create" do
    let(:template) { stages(:test_staging) }
    let(:copied_deploy) { deploys(:succeeded_test) }

    it "creates a new stage and deploys" do
      copied_deploy.update_column(:buddy_id, users(:admin).id)

      assert_difference 'Stage.count', +1 do
        assert_difference 'Deploy.count', +1 do
          post_create
          assert_response :created
        end
      end

      # copies over the buddy id and uses current user as use
      Deploy.first.user.must_equal user
      Deploy.first.buddy_id.must_equal copied_deploy.buddy_id
    end

    it "reuses an existing stage and deploys" do
      template.update_column(:name, Api::AutomatedDeploysController::STAGE_NAME)

      refute_difference 'Stage.count' do
        assert_difference 'Deploy.count', +1 do
          post_create
          assert_response :created
        end
      end
    end

    it "fails when no template was found" do
      template.update_column(:is_template, false)
      post_create
      assert_response :bad_request
      response.body.must_equal "{\"error\":\"Unable to find template for Project\"}"
    end

    it "fails when new stage could not be saved" do
      Stage.any_instance.expects(:valid?).returns(false)
      post_create
      assert_response :bad_request
      response.body.must_equal "{\"error\":\"Unable to save stage: []\"}"
    end

    it "fails when no deploy could be found" do
      Job.update_all(status: 'cancelled')
      post_create
      assert_response :bad_request
      response.body.must_equal "{\"error\":\"Unable to find successful deploy for Automated Deploys\"}"
    end

    it "fails when deploy could not be started" do
      Deploy.any_instance.expects(:valid?).returns(false) # validation fails
      post_create
      assert_response :bad_request
      response.body.must_equal "{\"error\":\"Unable to start deploy: []\"}"
    end
  end
end
