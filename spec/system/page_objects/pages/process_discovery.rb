# frozen_string_literal: true

module PageObjects
  module Pages
    class ProcessDiscovery < PageObjects::Pages::Base
      def visit_workflow
        page.visit("/processes")
        self
      end

      def visit_process_charts
        page.visit("/processes/charts")
        self
      end

      def has_quick_filters?
        has_css?(".process-quick-filters")
      end

      def select_process_view(view_label)
        find(".process-quick-filters__view-select").select(view_label)
        self
      end

      def has_process_view_option?(view_label)
        has_css?(".process-quick-filters__view-select option", text: view_label)
      end

      def has_no_process_view_option?(view_label)
        has_no_css?(".process-quick-filters__view-select option", text: view_label)
      end

      def has_workflow_burndown_chart?
        has_css?(".process-burndown")
      end

      def has_workflow_burndown_chart_canvas?
        has_css?(".process-burndown__chart canvas")
      end

      def has_workflow_chart_legend_step?(step_name)
        has_css?(".process-burndown__legend .process-burndown__legend-step", text: step_name)
      end

      def has_no_workflow_chart_legend_step?(step_name)
        has_no_css?(".process-burndown__legend .process-burndown__legend-step", text: step_name)
      end

      def has_workflow_chart_weeks_selector?
        has_css?(".process-quick-filters__chart-weeks-select")
      end

      def has_chart_weeks_option?(weeks)
        has_css?(".process-quick-filters__chart-weeks-select option[value='#{weeks}']")
      end

      def has_view_then_period_order?
        page.evaluate_script(<<~JS)
            (() => {
              const row = document.querySelector(".process-quick-filters");
              if (!row) {
                return false;
              }

              const view = row.querySelector(".process-quick-filters__view-select");
              const period = row.querySelector(".process-quick-filters__chart-weeks-select");
              if (!view || !period) {
                return false;
              }

              return !!(view.compareDocumentPosition(period) & Node.DOCUMENT_POSITION_FOLLOWING);
            })()
          JS
      end

      def has_workflow_chart_workflow_selector?
        has_css?(".process-burndown__workflow-select")
      end

      def select_chart_weeks(weeks)
        select = find(".process-quick-filters__chart-weeks-select")
        select.find("option[value='#{weeks}']").select_option
        self
      end

      def select_chart_workflow(name)
        find(".process-burndown__workflow-select").select(name)
        self
      end

      def workflow_chart_point_count
        find(".process-burndown__chart").native["data-point-count"].to_i
      end

      def toggle_my_categories
        find(".process-quick-filters__my-categories").click
        self
      end

      def toggle_overdue
        find(".process-quick-filters__overdue").click
        self
      end

      def set_step_filter(step)
        find(".process-quick-filters__step-input").fill_in(with: step)
        find(".process-quick-filters__apply-step").click
        self
      end

      def has_process_view_toggle?
        has_css?(".process-quick-filters__view-select")
      end

      def has_no_process_view_toggle?
        has_no_css?(".process-quick-filters__view-select")
      end

      def toggle_process_view
        select = find(".process-quick-filters__view-select")
        select.select(select.value == "kanban" ? "List" : "Kanban")
        self
      end

      def process_view_value
        find(".process-quick-filters__view-select").value
      end

      def has_kanban_board?
        has_css?(".process-kanban")
      end

      def has_kanban_column_for_step?(position)
        has_css?(".process-kanban__column[data-process-step-position='#{position}']")
      end

      def kanban_column_border_color(position)
        page.evaluate_script(<<~JS)
            (() => {
              const column = document.querySelector(
                '.process-kanban__column[data-process-step-position="#{position}"]'
              );
              if (!column) {
                return null;
              }

              return window.getComputedStyle(column).borderTopColor;
            })();
          JS
      end

      def has_kanban_card_for_topic?(topic_id)
        has_css?(".process-kanban__card[data-topic-id='#{topic_id}']")
      end

      def has_no_kanban_card_for_topic?(topic_id)
        has_no_css?(".process-kanban__card[data-topic-id='#{topic_id}']")
      end

      def has_kanban_card_for_topic_in_step?(topic_id, position)
        has_css?(
          ".process-kanban__column[data-process-step-position='#{position}'] .process-kanban__card[data-topic-id='#{topic_id}']",
        )
      end

      def has_no_kanban_card_for_topic_in_step?(topic_id, position)
        has_no_css?(
          ".process-kanban__column[data-process-step-position='#{position}'] .process-kanban__card[data-topic-id='#{topic_id}']",
        )
      end

      def has_kanban_tag_for_topic?(topic_id, tag_name)
        has_css?(
          ".process-kanban__card[data-topic-id='#{topic_id}'] .process-kanban__tags .discourse-tag[data-tag-name='#{tag_name}']",
        )
      end

      def has_no_kanban_tag_for_topic?(topic_id, tag_name)
        has_no_css?(
          ".process-kanban__card[data-topic-id='#{topic_id}'] .process-kanban__tags .discourse-tag[data-tag-name='#{tag_name}']",
        )
      end

      def has_kanban_legal_drop_target_for_step?(position)
        has_css?(".process-kanban__column--legal[data-process-step-position='#{position}']")
      end

      def has_kanban_illegal_drop_target_for_step?(position)
        has_css?(".process-kanban__column--illegal[data-process-step-position='#{position}']")
      end

      def drag_kanban_card_to_step(topic_id, position)
        page.execute_script(<<~JS, topic_id, position)
            const topicId = arguments[0];
            const stepPosition = arguments[1];
            const card = document.querySelector(
              `.process-kanban__card[data-topic-id="${topicId}"]`
            );
            const target = document.querySelector(
              `.process-kanban__column[data-process-step-position="${stepPosition}"] .process-kanban__cards`
            );

            if (!card || !target) {
              return;
            }

            const dataTransfer = new DataTransfer();
            card.dispatchEvent(
              new DragEvent("dragstart", {
                bubbles: true,
                cancelable: true,
                dataTransfer,
              })
            );
            target.dispatchEvent(
              new DragEvent("dragover", {
                bubbles: true,
                cancelable: true,
                dataTransfer,
              })
            );
            target.dispatchEvent(
              new DragEvent("drop", {
                bubbles: true,
                cancelable: true,
                dataTransfer,
              })
            );
            card.dispatchEvent(
              new DragEvent("dragend", {
                bubbles: true,
                cancelable: true,
              })
            );
          JS
        self
      end

      def start_drag_on_kanban_card(topic_id)
        page.execute_script(<<~JS, topic_id)
            const topicId = arguments[0];
            const card = document.querySelector(
              `.process-kanban__card[data-topic-id="${topicId}"]`
            );

            if (!card) {
              return;
            }

            const dataTransfer = new DataTransfer();
            const event = new DragEvent("dragstart", {
              bubbles: true,
              cancelable: true,
              dataTransfer,
            });
            card.dispatchEvent(event);
          JS
        self
      end

      def end_drag_on_kanban_card(topic_id)
        page.execute_script(<<~JS, topic_id)
            const topicId = arguments[0];
            const card = document.querySelector(
              `.process-kanban__card[data-topic-id="${topicId}"]`
            );

            if (!card) {
              return;
            }

            const event = new DragEvent("dragend", {
              bubbles: true,
              cancelable: true,
            });
            card.dispatchEvent(event);
          JS
        self
      end

      def move_kanban_card_with_key(topic_id, key)
        page.execute_script(<<~JS, topic_id, key)
            const id = arguments[0];
            const key = arguments[1];
            const card = document.querySelector(
              `.process-kanban__card[data-topic-id="${id}"]`
            );

            if (!card) {
              return;
            }

            card.focus();
            card.dispatchEvent(
              new KeyboardEvent("keydown", {
                key,
                bubbles: true,
                cancelable: true,
              })
            );
          JS
        self
      end

      def current_url
        page.current_url
      end
    end
  end
end
