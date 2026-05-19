export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("processes", function () {
      this.route("new");
      this.route("edit", { path: "/:process_id/edit" });
      this.route("steps", { path: "/:process_id/process-steps" }, function () {
        this.route("new"); // New workflow step route
        this.route("edit", { path: "/:step_id/edit" }); // Edit workflow step route
        this.route(
          "options",
          { path: "/:step_id/process-step-options" },
          function () {
            this.route("new"); // New workflow step option route
            this.route("edit", { path: "/:option_id/edit" }); // Edit workflow step option route
          }
        );
      });
    });
  },
};
