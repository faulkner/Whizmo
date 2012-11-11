root = global ? window

Whizmo = Whizmo || {}
root.Whizmo = Whizmo || {}

root.Template.main.error = ->
  Session.get('error')

root.Template.main.userName = ->
  user = Meteor.user()
  user?.profile?.name or user?.emails[0]?.address

root.Template.main.data = ->
  [3, 9, 5, 16, 23, 42]

root.Template.main.brag = ->
  [
    "My buildings have improved 85% over the past 3 weeks.",
    "My office building at 1 Carrot Way, Anytown USA is performing 23% better than industry average.",
    "Recent investments have improved 3 of my buildings by over $0.53 per square foot."
  ]

#Total Electricity Use (KwH/Year)	"Total Electricity Use per Square Foot
#(KwH/SF/Year)"	Benchmark (Average KwH/SF/Year)	Benchmark - Total Use	Potential Total KwH/Year Saved	Current Average Price/KwH	Potential Total $ Saved/Year
# 568,500 	 18.95 	 17.89 	 (1.06)	 31,800 	 11.56 	$367,608
# 1,441,600 	 18.02 	 18.39 	 0.37 	 (29,600)	 13.97 	-$413,512
# 1,235,650 	 19.01 	 18.26 	 (0.75)	 48,750 	 10.56 	$514,800
# 2,560,000 	 16.00 	 17.81 	 1.81 	 (289,600)	 13.85 	-$4,010,960


#
# when I change the benchmark choice for a building
# 
# => get the building in question
# => get the new benchmark in question
#
# change the building's benchmark to the new string
# calculate the buildings delta from benchmark
#       ( building.total_usage_kwh / building.size ) - benchmark.kwh_per_sf
#
# if the delta is > 0
#   building.benefit = 0
#   building.opportunity = delta * building.size * benchmark.utility_rate_flat_dol_per_kwh
#
#
# if the delta is < 0
#   building.benefit = delta * building.size * benchmark.utility_rate_flat_dol_per_kwh
#   building.opportunity = 0
#
#
# now we need to update the brags
#   what % of my portfolio has benefit > 0?
#
#   what buildings have benefit > 0
#
#   something fake like "Recent investments have improved 3 of my buildings by over $0.53 per square foot."
#

root.Template.main.benchmarks = ->
 [
    {
        "usage":"Office",
        "region":"Midwest",
        "kwh_per_sf":14,
        "utility_rate_flat_dol_per_kwh":0.10
    },
    {
        "usage":"Multifamily",
        "region":"Midwest",
        "kwh_per_sf":15,
        "utility_rate_flat_dol_per_kwh":0.10
    },
    {
        "usage":"Office",
        "region":"North East",
        "kwh_per_sf":12.3,
        "utility_rate_flat_dol_per_kwh":0.12
    },
    {
        "usage":"Multifamily",
        "region":"North East",
        "kwh_per_sf":15.3,
        "utility_rate_flat_dol_per_kwh":0.12
    },
    {
        "usage":"Office",
        "region":"West",
        "kwh_per_sf":13.7,
        "utility_rate_flat_dol_per_kwh":0.13
    },
    {
        "usage":"Multifamily",
        "region":"West",
        "kwh_per_sf":14,
        "utility_rate_flat_dol_per_kwh":0.13
    }
 ]
 
root.Template.main.building = ->
  [
    {
        "location":"5211 East Kellogg Avenue, Wichita, KS 67218",
        "usage":"Multifamily",
        "opportunity":367608,
        "benefit":0,
        "incentives":6,
        "size":30000,
        "total_usage_kwh":568500,
        "benchmark": "Midwest"
    },
    {
        "location":"333 Market Street, San Francisco, CA 94111",
        "usage":"Office",
        "opportunity":0,
        "benefit":413512,
        "incentives":1,
        "size":80000,
        "total_usage_kwh":1441600,
        "benchmark": "West"
    },
    {
        "location":"5300 South Howell Avenue, Milwaukee, WI 53207",
        "usage":"Office",
        "opportunity":514800,
        "benefit":0,
        "incentives":1,
        "size":65000,
        "total_usage_kwh":1235650,
        "benchmark": "Midwest"
    },
    {
        "location":"1 Wall Street, New York NY 10048",
        "usage":"Office",
        "opportunity":0,
        "benefit":4010960,
        "incentives":1,
        "size":160000,
        "total_usage_kwh":2560000,
        "benchmark": "North East"
    }
  ]

root.Template.main.content = ->
  Session.get('content')

root.Template.main.events =
  "click .blah": (event) ->
    console.log event


class root.Whizmo.AppRouter extends Backbone.Router
  routes:
    "": "index"
    "buildings": "buildings"
    "meters": "meters"
    "add": "add"
    "edit": "edit"
    "help": "help"
    "search/:query": "search"
    "*path": "error404"

  initialize: (broker) ->
    @app =
      broker: @broker

  edit: ->
    Session.set('content', {type: {edit: true}})

  add: ->
    Session.set('content', {type: {add: true}})

  buildings: ->
    Session.set('content', {type: {buildings: true}})

  meters: ->
    Session.set('content', {type: {meters: true}})

  index: ->
    Session.set('content', {type: {index: true}})

  help: ->
    Session.set('content', {type: {help: true}})

  error404: () ->
    document.title = "Error"
    Session.set('content', 'error')


Meteor.startup () ->
  broker = _.extend({}, Backbone.Events)
  appRouter = new root.Whizmo.AppRouter(broker)
  if not Backbone.history.start({pushState: false})
    appRouter.app.middle.$el.html = new root.Whizmo.Views.Error().render().$el

