root = global ? window

# way to suck at everything, Handlebars.
Handlebars.registerHelper 'op', (v1, v2) ->
  ' selected="selected"' if v1 == v2

Handlebars.registerHelper 'num_format', (number) ->
  x = number.toString().split('.')
  x1 = x[0]
  x2 = if x.length > 1 then '.' + x[1] else ''
  rgx = /(\d+)(\d{3})/
  while rgx.test(x1)
    x1 = x1.replace(rgx, '$1' + ',' + '$2')
  x1 + x2

Whizmo = Whizmo || {}
root.Whizmo = Whizmo

Buildings = new Meteor.Collection('buildings')
Benchmarks = new Meteor.Collection('benchmarks')
Meters = new Meteor.Collection('meters')

root.Template.main.error = ->
  Session.get('error')

root.Template.main.userName = ->
  user = Meteor.user()
  user?.profile?.name or user?.emails[0]?.address

root.Template.main.data = ->
  [3, 9, 5, 16, 23, 42]

root.Whizmo.Data.brags =
  'good': [
    "My buildings have improved 85% over the past 3 weeks.",
    "My office building at 1 Carrot Way, Anytown USA is performing 23% better than industry average.",
    "Recent investments have improved 3 of my buildings by over $0.53 per square foot."
  ],
  'kindagood': [
    "My buildings suck energy.",
    "Hello",
    "My investments are killing me $0.53 per square foot."
  ],
  'totallyawesome': [
    "My buildings suck energy.",
    "Hello",
    "My investments are killing me $0.53 per square foot."
  ],
  'default': [
    "I am beating the industry average with 50% of my portfolio.",
    "Our capital improvements have reduced the carbon footprint of the portfolio by 23,000 tons of CO2.",
    "My office building at 1 Wall Street, New York NY is is using 43% less energy than the industry average.",
    "We are saving $2,010,960 in energy costs at 1 Wall Street, New York NY compared to our neighbors."
  ]


root.Template.brags.brag = ->
  if Session.get('brag') is 'good'
    Whizmo.Data.brags.good
  else
    Whizmo.Data.brags.default


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
#       EXAMPLE "I am outperforming industry benchmarks with 85% of my portfolio."
#
#   what buildings have benefit > 0
#       EXAMPLE "My office building at 1 Carrot Way, Anytown USA is performing 23% better than industry average.",
#
#   something fake like "Recent investments have improved 3 of my buildings by over $0.53 per square foot."
#

root.Template.main.benchmarks = (building) ->
  Benchmarks.find({usage: building.usage})
 
root.Template.main.building = ->
  Buildings.find()

root.Template.main.content = ->
  Session.get('content')

root.Template.main.events =
  "click .blah": (event) ->
    console.log event

  "click .delete-building": (event) ->
    id = $(event.target).parents('tr').data('id')
    Buildings.remove({_id: id})

  "change .benchmark_id": (event) ->
    id = $(event.target).parents('tr').data('id')
    building = Buildings.findOne({_id: id})
    benchmark = Benchmarks.findOne({_id: event.target.value})

    delta = building.total_usage_kwh / building.size - benchmark.kwh_per_sf
    diff = Math.round(delta * building.size * benchmark.utility_rate_flat_dol_per_kwh)
    # TODO: why are these two fields?  Just to make templating easier?
    if delta >= 0
      building.benefit = 0
      building.opportunity = diff
    else
      building.benefit = diff
      building.opportunity = 0

    building.benchmark_id = benchmark._id
    Buildings.update({_id: id}, building)

    #return false
    #if building.benefit
    #  Session.set('brag', 'good')
    #else
    #  Session.set('brag', 'default')
    #  #event.stopProgation()
    #return false

class Whizmo.AppRouter extends Backbone.Router
  routes:
    "": "index"
    "summary": "summary"
    "investment": "investment"
    "portfolio": "portfolio"
    "about": "about"
    "add": "add"
    "help": "help"
    "search/:query": "search"
    "*path": "error404"

  tab: (name) ->
    if not $('#' + name).hasClass('active')
      $('[href=#' + name + ']').click()

  summary: ->
    @tab 'summary'
    Session.set('content', {type: {summary: true}})

  add: ->
    Session.set('content', {type: {add: true}})

  investment: ->
    @tab 'investment'
    Session.set('content', {type: {investment: true}})

  portfolio: ->
    @tab 'portfolio'
    Session.set('content', {type: {portfolio: true}})

  about: ->
    @tab 'about'

  index: ->
    Session.set('content', {type: {index: true}})

  help: ->
    Session.set('content', {type: {help: true}})

  error404: () ->
    #document.title = "Error"
    Session.set('content', 'error')


Meteor.startup () ->
  appRouter = new Whizmo.AppRouter()
  if not Backbone.history.start(pushState: true)
    appRouter.app.middle.$el.html = new Whizmo.Views.Error().render().$el

  $(document).on 'click', 'a:not([data-bypass])', (evt) ->
    href = $(@).attr('href')
    protocol = @protocol + '//'

    if href?[0...protocol.length] != protocol && href.indexOf('javascript:') != 0
      evt.preventDefault()
      Backbone.history.navigate(href, true)

  #root.Whizmo.Data.Graph.TimeSeries()
  #root.Whizmo.Data.Graph.BarChart()
  #root.Whizmo.Data.Graph.BubbleChart()

