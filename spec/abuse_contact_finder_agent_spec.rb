require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::AbuseContactFinderAgent do
  before(:each) do
    @valid_options = Agents::AbuseContactFinderAgent.new.default_options
    @checker = Agents::AbuseContactFinderAgent.new(:name => "AbuseContactFinderAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
