require 'spec_helper'

module Hdo
  describe IssueUpdater do
    let(:user) { User.make! }

    describe 'vote proposition types' do
      it "updates a single vote's proposition_type" do
        issue = Issue.make! vote_connections: [VoteConnection.make!]

        issue.votes.each { |v| v.proposition_type.should be_blank }

        votes = {
          issue.votes[0].id => {
            direction: 'for',
            weight: 1.0,
            title: 'title!!!!!!!!',
            proposition_type: Vote::PROPOSITION_TYPES.first
          }
        }

        IssueUpdater.new(issue, {}, votes, user).update!

        issue.reload

        issue.votes.each do |vote|
          vote.proposition_type.should == Vote::PROPOSITION_TYPES.first
        end
      end

      it "updates one of many vote's proposition_type" do
        issue = Issue.make! vote_connections: [VoteConnection.make!, VoteConnection.make!]
        issue.votes.each { |v| v.proposition_type.should be_blank }

        votes = {
          issue.votes[0].id => {
            direction: 'for',
            weight: 1.0,
            title: 'title!!!!!!!!',
            proposition_type: Vote::PROPOSITION_TYPES.first
          },
          issue.votes[1].id => {
            direction: 'for',
            weight: 1.0,
            title: 'title!!!!!!!!',
            proposition_type: ""
          }
        }

        IssueUpdater.new(issue, {}, votes, user).update!
        issue.reload

        issue.votes[0].proposition_type.should == Vote::PROPOSITION_TYPES.first
      end

      it "updates multiple vote's proposition_type simultaneously" do
        issue = Issue.make! vote_connections: [VoteConnection.make!, VoteConnection.make!]
        issue.votes.each { |v| v.proposition_type.should be_blank }

        votes = {
          issue.votes[0].id => {
            direction: 'for',
            weight: 1.0,
            title: 'title!!!!!!!!',
            proposition_type: Vote::PROPOSITION_TYPES.first
          },
          issue.votes[1].id => {
            direction: 'for',
            weight: 1.0,
            title: 'title!!!!!!!!',
            proposition_type: Vote::PROPOSITION_TYPES.last
          }
        }

        IssueUpdater.new(issue, {}, votes, user).update!
        issue.reload

        issue.votes[0].proposition_type.should == Vote::PROPOSITION_TYPES.first
        issue.votes[1].proposition_type.should == Vote::PROPOSITION_TYPES.last
      end

      it 'does not touch the issue if proposition type is already nil or empty' do
        vote_connection = VoteConnection.make!(matches: true)
        vote            = vote_connection.vote
        issue           = Issue.make! vote_connections: [vote_connection]

        vote.proposition_type.should be_nil
        issue.last_updated_by.should be_nil

        votes = {
          vote.id => {
            direction: 'for',
            weight: vote_connection.weight,
            title: vote_connection.title,
            proposition_type: '' # input is an empty string
          }
        }

        IssueUpdater.new(issue, {}, votes, user).update!
        issue.last_updated_by.should be_nil
      end
    end
  end
end