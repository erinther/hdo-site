require 'spec_helper'

module Hdo
  module Search
    describe Searcher do
      let(:query) { "some query" }
      let(:searcher) { Searcher.new(query) }
      let(:tire_search) { mock("tire search", sort: nil, results: []) }
      let(:tire_query) { mock("tire query") }

      it 'searches all indeces for the given query' do
        search = mock("search")
        Tire.should_receive(:search).
             with(hash_including('issues')).
             and_yield(tire_search).and_return(tire_search)

        # testing a block DSL sucks...
        tire_search.should_receive(:size).and_return 25
        tire_search.should_receive(:query).and_yield(tire_query)
        tire_query.should_receive(:string).
                   with(query, hash_including(default_operator: 'AND'))

        response = searcher.all
        response.should be_kind_of(Searcher::Response)
        response.should be_success
        response.results.should == []
      end

      it 'returns a failed response if the search server is down' do
        Tire.should_receive(:search).and_raise Errno::ECONNREFUSED

        response = searcher.all
        response.should be_kind_of(Searcher::Response)
        response.should_not be_success
        response.exception.should be_kind_of(Errno::ECONNREFUSED)
        response.results.should be_nil
      end

      it 'returns a failed response if the search request fails' do
        Tire.should_receive(:search).and_raise Errno::ECONNREFUSED

        response = searcher.all
        response.should be_kind_of(Searcher::Response)
        response.should_not be_success
        response.exception.should be_kind_of(Errno::ECONNREFUSED)
        response.results.should be_nil
      end
    end
  end
end