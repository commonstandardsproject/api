require 'spec_helper'
require_relative "../../models/user"
require_relative '../../api/api'

describe "PullRequest API" do

  def app
   API::API
 end

  before(:each) do
    @user = User.create({
      id: "tester",
      email: "test@test.com",
      apiKey: "testing",
      profile: {
        name: "Tester"
      },
      committer: true
    })
    header "Authorization","TEST"
    header "Api-Key","testing"
  end

  describe "GET" do
    it "should work" do
      PullRequest.insert(PullRequest.new(:id => "testing"))
      response = get '/api/v1/pull_requests/testing'
      model = JSON.parse(response.body)
      expect(model["data"]["id"]).to eq("testing")
    end
  end

  describe "GET PRs for user" do
    it "should work" do
      User.create({ id: "user-1" })
      PullRequest.insert(PullRequest.new(:id => "testing", submitterId: "user-1"))
      response = get '/api/v1/pull_requests/user/user-1'
      model = JSON.parse(response.body)
      expect(model["data"][0]["id"]).to eq("testing")
    end
  end

  describe "POST new, blank PR" do
    it "should work" do
      allow(AsanaTask).to receive(:create_task).and_return(OpenStruct.new({id: "asana-task-1"}))
      allow(PostmarkClient).to receive(:deliver_with_template)
      response = post '/api/v1/pull_requests'
      model = JSON.parse(response.body)
      expect(model["data"]["submitterId"]).to eq("tester")
      expect(model["data"]["submitterEmail"]).to eq("test@test.com")
      expect(model["data"]["activities"][0]["type"]).to eq("created")
    end
  end

  describe "POST PR from existing standard set" do
    it "should work" do
      StandardSet.update({"id" => "md-math-grade1", "title" => "MD Math Gr 1"}, {cache_standards: false, send_to_algolia: false})
      allow(AsanaTask).to receive(:create_task).and_return(OpenStruct.new({id: "asana-task-1"}))
      allow(PostmarkClient).to receive(:deliver_with_template)
      response = post '/api/v1/pull_requests', :standard_set_id => "md-math-grade1"
      model = JSON.parse(response.body)
      expect(model["data"]["forkedFromStandardSetId"]).to eq("md-math-grade1")
      expect(model["data"]["standardSet"]["id"]).to eq("md-math-grade1")
      expect(model["data"]["standardSet"]["title"]).to eq("MD Math Gr 1")
    end
  end

  describe "POST update PR" do
    it "should work" do
      allow(AsanaTask).to receive(:create_task).and_return(OpenStruct.new({id: "asana-task-1"}))
      allow(PostmarkClient).to receive(:deliver_with_template)
      pull_request = PullRequest.new({
        id: "1",
        submitterId: "tester",
        submitterEmail: "testing@gmail.com",
        submitterName: "Scott",
        standardSet: StandardSet.new({
          id: "1",
          title: "MD Math Grade 1",
          educationLevels: [],
          subject: "math",
          license: StandardSet::License.new,
          jurisdiction: StandardSet::Jurisdiction.new(id: 1, title: "MD")
        })
      })
      PullRequest.insert(pull_request)
      pull_request.standardSet.title = "MD Math Grade 2"
      response = post "/api/v1/pull_requests/#{pull_request.id}", :standard_set_id => "md-math-grade1", data: pull_request.to_hash
      model = PullRequest.find("1")
      expect(model.standardSet.title).to eq("MD Math Grade 2")
    end
  end

  describe "changing status or comments" do
    before(:each) do
      @pull_request = PullRequest.new({
        id: "1",
        submitterId: "tester",
        submitterEmail: "testing@gmail.com",
        submitterName: "Scott",
        asanaTaskId: "task-1",
        standardSet: StandardSet.new({
          id: "1",
          title: "MD Math Grade 1",
          educationLevels: [],
          subject: "math",
          license: StandardSet::License.new,
          jurisdiction: StandardSet::Jurisdiction.new(id: 1, title: "MD")
        })
      })
      PullRequest.insert(@pull_request)
    end

    describe "POST /:id/submit" do
      it "should mark as submitted" do
        allow(AsanaTask).to receive(:approval_requested)

        post "/api/v1/pull_requests/#{@pull_request.id}/submit"
        # expect(AsanaTask).to have_received(:approval_requested).with("task-1")
        model = PullRequest.find(@pull_request.id)
        expect(model.status).to eq("approval-requested")
      end
    end

    describe "POST /:id/change_status" do
      it "should reject" do
        allow(AsanaTask).to receive(:reject)
        allow(PostmarkClient).to receive(:deliver_with_template)

        post "/api/v1/pull_requests/#{@pull_request.id}/change_status", status: "rejected"
        # expect(AsanaTask).to have_received(:reject).with("task-1")
        expect(PostmarkClient).to have_received(:deliver_with_template)

        pr = PullRequest.find(@pull_request.id)
        expect(pr.status).to eq("rejected")
      end

      it "should approve and apply" do
        allow(AsanaTask).to receive(:approve)
        allow(CachedStandards).to receive(:one)
        allow(SendToAlgolia).to receive(:standard_set)
        allow(PostmarkClient).to receive(:deliver_with_template)

        post "/api/v1/pull_requests/#{@pull_request.id}/change_status", status: "approved"
        # expect(AsanaTask).to have_received(:approve).with("task-1")
        expect(PostmarkClient).to have_received(:deliver_with_template)

        pr = PullRequest.find(@pull_request.id)
        expect(pr.status).to eq("approved")

        ss = StandardSet.find(@pull_request.standardSet.id)
        expect(ss.title).to eq(@pull_request.standardSet.title)
      end

      it "should revise-and-resubmit" do
        allow(AsanaTask).to receive(:revise_and_resubmit)
        allow(PostmarkClient).to receive(:deliver_with_template)

        post "/api/v1/pull_requests/#{@pull_request.id}/change_status", status: "revise-and-resubmit"
        # expect(AsanaTask).to have_received(:revise_and_resubmit).with("task-1")
        expect(PostmarkClient).to have_received(:deliver_with_template)

        pr = PullRequest.find(@pull_request.id)
        expect(pr.status).to eq("revise-and-resubmit")
      end
    end

    describe "POST /:id/comment" do
      it "should post an admin's comment" do

        allow(AsanaTask).to receive(:add_comment_from_approver)
        allow(PostmarkClient).to receive(:deliver_with_template)
        post "/api/v1/pull_requests/#{@pull_request.id}/comment", comment: "love it"

        pr = PullRequest.find(@pull_request.id)
        expect(pr.activities.first.title).to eq("love it")
        # expect(AsanaTask).to have_received(:add_comment_from_approver).with("task-1", "love it", @user[:profile][:name])
        expect(PostmarkClient).to have_received(:deliver_with_template)
      end

      it "should post a submitters comment" do
        # make user not a committer
        $db[:users].find({_id: "tester"}).find_one_and_update({"$set" => {committer: false}})

        allow(AsanaTask).to receive(:add_comment_from_submitter)
        post "/api/v1/pull_requests/#{@pull_request.id}/comment", comment: "love it"

        pr = PullRequest.find(@pull_request.id)
        expect(pr.activities.first.title).to eq("love it")
        # expect(AsanaTask).to have_received(:add_comment_from_submitter).with("task-1", "love it", @user[:profile][:name])
      end
    end

  end
end
