# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe "Process transition legacy action code support" do
  it "keeps a client translation for legacy Workflow-era small action posts" do
    locale_path = File.expand_path("../../config/locales/client.en.yml", __dir__)
    source = File.read(locale_path)

    expect(source).to include('workflow_transition: "acted upon topic in a process %{when}"')
  end

  it "keeps a small action icon for legacy Workflow-era small action posts" do
    initializer_path =
      File.expand_path(
        "../../assets/javascripts/discourse/initializers/init-process-manager.gjs",
        __dir__,
      )
    source = File.read(initializer_path)

    expect(source).to include('api.addPostSmallActionIcon("workflow_transition", "right-left")')
    expect(source).to include("Remove this legacy action code")
  end
end
