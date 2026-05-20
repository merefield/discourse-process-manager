# frozen_string_literal: true

Fabricator(:process_stat, from: "ProcessManager::ProcessStat") do
  cob_date { Date.current }
  count { 0 }
  workflow { Fabricate(:process) }
  workflow_step { Fabricate(:process_step) }
end
