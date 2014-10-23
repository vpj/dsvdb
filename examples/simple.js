// Generated by CoffeeScript 1.8.0
(function() {
  var Fruit, db, dsvdb, models,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  dsvdb = require('../index');

  Fruit = (function(_super) {
    __extends(Fruit, _super);

    function Fruit() {
      return Fruit.__super__.constructor.apply(this, arguments);
    }

    Fruit.prototype.model = 'Fruit';

    Fruit.defaults({
      handle: {
        type: 'string',
        "default": ''
      },
      name: {
        type: 'string',
        "default": ''
      },
      price: {
        type: 'decimal',
        "default": ''
      }
    });

    return Fruit;

  })(dsvdb.Model);

  models = {
    Fruit: Fruit
  };

  db = new dsvdb.Database('../testdata', models);

  db.loadFiles('Fruit', function(err, model) {
    return console.log(err, model);
  });

}).call(this);
