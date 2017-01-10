angular.module 'beebon_dashboard', [
  'ngRoute'
  'ngResource'
  'ui.router'
  'hljs'
  'ui.bootstrap'
]
.config ['$stateProvider', '$urlRouterProvider', ($stateProvider, $urlRouterProvider)->
  $urlRouterProvider.otherwise '/'

  $stateProvider
  .state
      name: 'keys'
      url: '/'
      controller: 'MainBeebonController as mainCtrl'
      templateUrl: '/partials/list'
  .state
      name: 'keys.view'
      url: 'view/:key'
      controller: 'KeysBeebonController as listCtrl'
      templateUrl: '/partials/keys'
  .state
      name: 'keys.dashboard'
      url: 'dashboard'
      controller: 'DashboardBeebonController as dashboardCtrl'
      templateUrl: '/partials/dashboard'
  .state
      name: 'keys.create'
      url: 'create'
      controller: 'DashboardBeebonCreateController as createCtrl'
      templateUrl: '/partials/create'
]
.factory 'Keys', ['$resource', ($resource)->
  $resource '/keys/:key/:id', id: '@_id'
]
.factory 'Models', ['$http', ($http)->
  $http.get '/keys/models'
]
.controller 'MainBeebonController', ['Models', (Models)->
  self = this
  this.models = []
  Models.then (response)->
    self.models = response.data
    console.log self.models
  console.log 'asd'
]
.controller 'KeysBeebonController', ['$state', '$stateParams', '$http', 'Keys', ($state, $stateParams, $http, Keys)->
  self = this
  this.key = $stateParams.key
  this.page = 1
  this.limit = 10
  this.offset = 0
  this.itemCount = 0

  this.selectedItem = null

  this.keys = []
  this.getKeys = ()->
    self.keys = Keys.query
      key: this.key
      $limit: this.limit
      $offset: this.offset
      $select: ['id', 'tag', 'timestamp']

    console.log self.keys
  console.log this.keys

  $http.get "/keys/#{this.key}/count"
  .then (response)->
    self.itemCount = response.data.totalItemCount
    console.log self.itemCount

  this.setPage = ()->
    this.offset = (this.page - 1) * this.limit
    this.getKeys()


  this.selectItem = (id)->
    self.selectedItem = Keys.get
      key: self.key
      id: id
    , ()->
      self.selectedItem.payload = JSON.stringify self.selectedItem.payload, null, '\t'
      console.log self.selectedItem
  this.getKeys()

  this.logCurl = 'curl -X POST -H "Content-Type: application/json" -d \'{"data":"testData"}\' "http://beeboncollector/api/log/' + this.key + '"'
  this.taskCurl = 'curl -X POST -H "Content-Type: application/json" -d \'{"data":"testData"}\' "http://beeboncollector/api/task/' + this.key + '"'
  this.taskStatusCurl = 'curl -X GET "http://beeboncollector/api/task/' + this.key + '/status/:id"'
]
.controller 'DashboardBeebonController', ['$http', 'Models', ($http, Models)->
  self = this
  this.models = []
  this.date = moment().toDate()
  this.options = {
    initDate: moment().toDate()
    maxDate: moment().toDate()
  }
  this.show = ()->
    console.log self.models
    for key of self.models
      model = self.models[key]
      renderModelChart model

  renderModelChart = (model)->
    date = moment(self.date).format('YYYY-MM-DD')
    $http.get "/keys/#{model}/chart/#{date}"
    .then (response)->
      console.log 'response.data', response.data
      c3.generate
        bindto: "##{model}Chart"
        data: response.data

  Models.then (response)->
    self.models = response.data
    self.show()
  console.log this.models
]
.controller 'DashboardBeebonCreateController', [
  '$http', '$state', ($http, $state)->
    @create = ()->
      if this.key.name
        $http.get "/keys/#{this.key.name}/create"
        .then (response)->
          $state.go 'keys', {}, reload: true

    @key = {}
    console.log @create
]