# frozen_string_literal: true
require_relative "../test_helper"

SingleCov.covered!

describe SamsonKubernetes do
  describe :stage_permitted_params do
    it "adds ours" do
      Samson::Hooks.fire(:stage_permitted_params).must_include :kubernetes
    end
  end

  describe :deploy_permitted_params do
    it "adds ours" do
      params = Samson::Hooks.fire(:deploy_permitted_params).flatten
      params.must_include :kubernetes_rollback
      params.must_include :kubernetes_reuse_build
    end
  end

  describe :build_permitted_params do
    it "adds ours" do
      Samson::Hooks.fire(:build_permitted_params).must_include :kubernetes_job
    end
  end

  describe :deploy_group_permitted_params do
    it "adds ours" do
      params = Samson::Hooks.fire(:deploy_group_permitted_params).flatten
      params.must_include cluster_deploy_group_attributes: [:kubernetes_cluster_id, :namespace]
    end
  end

  describe :link_parts_for_resource do
    def link_parts(resource)
      Samson::Hooks.fire(:link_parts_for_resource).to_h.fetch(resource.class.name).call(resource)
    end

    it "links to deploy group role" do
      dg_role = kubernetes_deploy_group_roles(:test_pod1_app_server)
      link_parts(dg_role).must_equal ["Foo role app-server for Pod1", dg_role]
    end

    it "links to role" do
      role = kubernetes_roles(:app_server)
      link_parts(role).must_equal ["Foo role app-server", [role.project, role]]
    end

    it "links to limit" do
      limit = Kubernetes::UsageLimit.create!(memory: 10, cpu: 10)
      link_parts(limit).must_equal ["Limit for  on All", limit]
    end

    it "links to cluster" do
      cluster = kubernetes_clusters(:test_cluster)
      link_parts(cluster).must_equal ["test", cluster]
    end
  end
end
