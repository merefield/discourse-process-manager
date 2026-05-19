import { setupTest } from "ember-qunit";
import { module, test } from "qunit";

module(
  "Unit | Route | admin-plugins/show/processes/steps/options/edit",
  function (hooks) {
    setupTest(hooks);

    test("it loads edit dependencies without requiring nested router state", async function (assert) {
      const route = this.owner.lookup(
        "route:admin-plugins/show/processes/steps/options/edit"
      );

      let processStepParams;
      route.store = {
        async findAll(type, params) {
          switch (type) {
            case "process-option":
              return { content: [{ id: 1, name: "Start", slug: "start" }] };
            case "process-step":
              processStepParams = params;
              return {
                content: [
                  { id: 3, process_id: 12 },
                  { id: 4, process_id: 12 },
                ],
              };
            default:
              throw new Error(`unexpected type: ${type}`);
          }
        },
      };

      const controller = {
        values: {},
        set(key, value) {
          this.values[key] = value;
        },
      };
      const model = { process_id: 12, process_step_id: 4 };

      await route.setupController(controller, model);

      assert.deepEqual(processStepParams, { process_id: 12 });
      assert.strictEqual(controller.values.processOptions.length, 1);
      assert.strictEqual(controller.values.processSteps.length, 2);
      assert.strictEqual(controller.values.processStep.id, 4);
    });
  }
);
