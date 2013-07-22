module = angular.module("alchemy.directives", [])

module.directive("mucMessages", ->
        return {
                restrict: 'E'
                translude: true
                template: "<li ng-repeat='msg in messages' class='muc-message'>{{ msg.from }} said: {{ msg.text }}</li>"
                scope:
                        messages: "=messages"

                constructor: ->
                        console.debug("yeah")

                link: (scope, element, attrs) =>
                        scope.$watch('messages', (oldMessages, newMessages)=>
                                console.debug("msg changed!")
                        )
        })
