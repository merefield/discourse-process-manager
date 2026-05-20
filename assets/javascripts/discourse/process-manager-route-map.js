export default {
  resource: "discovery",

  map() {
    this.route("processCharts", { path: "/processes/charts" });
  },
};
