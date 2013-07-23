module = angular.module("alchemy.directives", [])

module.directive("mucMessages", ($timeout) ->
        return {
                restrict: 'EA'
                transclude: true
                replace: true
                # templateUrl: "partials/message-list.html"
                template: '<span ng-transclude></span>'

                constructor: ->
                        console.debug("yeah")

                link: ($scope, $element, $attrs) =>

                        replaceURLWithHTMLLinks = (text) ->
                                exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
                                return text.replace(exp,"<a href='$1' target='_new'>$1</a>")

                        # Allow to process AFTER rendering using queue
                        $timeout(->
                                el = $($element)
                                el.html(replaceURLWithHTMLLinks(el.text()))
                                el.children('a').oembed(null, {maxHeight: '200px'})
                        , 0)


        })
