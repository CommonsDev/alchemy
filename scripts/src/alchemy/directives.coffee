module = angular.module("alchemy.directives", [])

module.directive("fileUpload", ($timeout) ->
        return {
                restrict: 'E'
                replace: true
                transclude: true

                scope:
                        bucket: '@'
                        dropzone: '@'

                template: '<form><input type="hidden" name="bucket" value="{{ bucket }}"/><input type="hidden" name="tags" value="plop"/><input class="fileupload" type="file" name="file" multiple></form>'

                link: ($scope, $element, $attrs) =>
                        $timeout(=>
                                $($element).fileupload(
                                        url: "http://localhost:8000/bucket/upload/"
                                        dropZone: "\##{$scope.dropzone}"
                                        dataType: 'json'
                                        done: (e, data) =>
                                                $.each(data.result, (idx, file) =>
                                                        $scope.$emit('file-uploaded', file)
                                                )
                                )
                        , 0)

                constructor: ->
                        console.debug("init fileupload")
        }

)

module.directive("masonry", ($parse, $timeout) ->
        return {
                restrict: 'AC',
                link: (scope, elem, attrs) ->
                        elem.masonry({ itemSelector: '.masonry-brick'});
                        # elem.masonry({ itemSelector: '.masonry-item', columnWidth: 140, gutterWidth: $parse(attrs.masonry)(scope) });

                controller : ($scope, $element) ->
                        bricks = []
                        this.addBrick = (brick) ->
                                bricks.push(brick)

                        this.removeBrick = (brick) ->
                                index = bricks.indexOf(brick)
                                if(index!=-1)
                                        bricks.splice(index,1)

                        $scope.$watch(->
                                return bricks
                        , ->
                                # triggers only once per list change (not for each brick)
                                console.log('reload')
                                $element.masonry('reloadItems')
                        , true)
        }
)

module.directive('masonryBrick', ($compile) ->
    return {
        restrict: 'AC'
        require : '^masonry'

        link: (scope, elem, attrs,ctrl) ->
                ctrl.addBrick(scope.$id)

                scope.$on('$destroy', ->
                        ctrl.removeBrick(scope.$id)
                )
        }
)


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
