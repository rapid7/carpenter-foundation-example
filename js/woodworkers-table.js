// Generated by CoffeeScript 1.8.0
(function() {
  define(['carpenter'], function(Carpenter) {
    return new Carpenter.Controller({
      title: 'Woodworkers',
      region: new Backbone.Marionette.Region({
        el: '#woodworkers-table-region'
      }),
      collection: new Backbone.Collection([], {
        url: 'js/woodworkers.json'
      })
    });
  });

}).call(this);

//# sourceMappingURL=woodworkers-table.js.map
