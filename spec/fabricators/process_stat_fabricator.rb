# frozen_string_literal: true

Fabricator(:process_stat, from: "ProcessManager::ProcessStat") do
  cob_date { Date.current }
  count { 0 }
  process_id { Fabricate(:process).id }
  process_step_id { Fabricate(:process_step).id }
end
