export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("processes", function () {
      this.route("new");
      this.route("edit", { path: "/:process_id/edit" });
      this.route("steps", { path: "/:process_id/process-steps" }, function () {
        this.route("new"); // New process step route
        this.route("edit", { path: "/:step_id/edit" }); // Edit process step route
        this.route(
          "options",
          { path: "/:step_id/process-step-options" },
          function () {
            this.route("new"); // New process step option route
            this.route("edit", { path: "/:option_id/edit" }); // Edit process step option route
          }
        );
      });
    });
  },
};
