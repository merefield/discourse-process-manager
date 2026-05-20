import { setupTest } from "ember-qunit";
import { module, test } from "qunit";

module(
  "Unit | Route | admin-plugins/show/processes/steps/options",
  function (hooks) {
    setupTest(hooks);

    test("it resolves process steps from the expected parent route model", async function (assert) {
      const route = this.owner.lookup(
        "route:admin-plugins/show/processes/steps/options"
      );

      const processSteps = [
        { id: 1, process_id: 42 },
        { id: 2, process_id: 42 },
      ];
      processSteps.findBy = (key, value) =>
        processSteps.find((step) => step[key] === value);

      route.modelFor = (routeName) => {
        assert.strictEqual(
          routeName,
          "adminPlugins.show.processes.steps",
          "uses the canonical parent route key"
        );
        return processSteps;
      };

      route.store = {
        async findAll(type, params) {
          assert.strictEqual(type, "process-step-option");
          assert.deepEqual(params, { process_step_id: 2, process_id: 42 });
          return { content: [{ id: 99 }] };
        },
      };

      const result = await route.model({ step_id: "2" });
      assert.deepEqual(result, [{ id: 99 }]);
    });
  }
);
