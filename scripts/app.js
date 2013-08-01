config = {
    templateBaseUrl: '/views/',
    REST_URI: 'http://carpe.local\\:8000/'
}

app = angular.module('alchemy', ['alchemy.controllers', 'alchemy.services', 'alchemy.directives']);

// Config
app.constant('moduleTemplateBaseUrl', config.templateBaseUrl + 'map/');

app.config(['$locationProvider', '$routeProvider', 'moduleTemplateBaseUrl', function($locationProvider, $routeProvider, moduleTemplateBaseUrl){
					   $locationProvider.html5Mode(true);
					   $routeProvider
					       .when('/:slug', {
						     })
					       .when('/new', {
							 templateUrl: moduleTemplateBaseUrl + 'new.html',
							 controller: 'MapNewCtrl'
						     })
						.when('/marker/detail/:markerId', {
							  templateUrl: moduleTemplateBaseUrl + 'marker_detail.html',
							  controller: 'MapMarkerDetailCtrl'
						      })
						.when('/marker/new', {
							  templateUrl: moduleTemplateBaseUrl + 'marker_new.html',
							  controller: 'MapMarkerNewCtrl'
						      })
					       .otherwise({redirectTo: '/'});
				       }
				      ])

app.run(['$rootScope', function($rootScope) {
  $rootScope.MEDIA_URI = 'http://carpe.local:8000';
  $rootScope.CONFIG = config;
}]);
