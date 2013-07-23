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

                                # Make url clickable
                                el.html(replaceURLWithHTMLLinks(el.text()))

                                # Preview pictures
                                el.find("a[href$='.png'], a[href$='.jpg'], a[href$='.tiff'], a[href$='.gif']").each(->
                                        console.debug("converting picture")
                                        img = $("<img>", {src: this.href, class: "preview"})
                                        $(this).replaceWith(img)
                                )

                                # Embed media
                                el.find('a').oembed(null, {maxHeight: '200px'})

                        , 0)


        })
