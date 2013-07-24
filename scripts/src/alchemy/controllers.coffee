module = angular.module('alchemy.controllers', ['http-auth-interceptor'])

class AlchemyController
        constructor: (@$scope, @jabber) ->
                @$scope.room_names = ["#test@conference.carpe.local"] #, "#yeah@conference.carpe.local"]

                @$scope.jabber = @jabber


class VideoChatController
        waitForRemoteVideo: (selector, sid) =>
                sess = @jingle.sessions[sid]
                videoTracks = sess.remoteStream.getVideoTracks()

                if videoTracks.length == 0 or selector[0].currentTime > 0
                        $(document).trigger('callactive.jingle', [selector, sid])
                        window.RTC.attachMediaStream(selector, sess.remoteStream); # FIXME: why do i have to do this for FF?
                        console.log('waitForremotevideo', sess.peerconnection.iceConnectionState, sess.peerconnection.signalingState)
                else
                        setTimeout(=>
                                this.waitForRemoteVideo(selector, sid)
                        , 100)


        constructor: (@$scope, @jabber) ->
                @jingle = @jabber.connection.jingle

                @jingle.PRANSWER = false
                @jingle.AUTOACCEPT = true
                @jingle.ice_config = {iceServers: [{url: 'stun:carpe.local:3478'}]}
                @jingle.MULTIPARTY = false
                @jingle.pc_constraints = window.RTC.pc_constraints
                # @jingle.media_constraints.mandatory['MozDontOfferDataChannel'] = true

                @$scope.chat = this.chat

                $(document).bind('callincoming.jingle', =>
                        console.debug("NOT IMPLEMENTED callincoming")
                )

                $(document).bind('callactive.jingle', (event, videoelem, sid) =>
                        $(videoelem).appendTo('#remotevideo')
                        $(videoelem).show()
                )
                $(document).bind('callterminated.jingle', =>
                        console.debug("NOT IMPLEMENTED")
                )

                $(document).bind('remotestreamadded.jingle', (event, data, sid) =>
                        console.debug("remoteadded stream added")

                        if $('#largevideo_' + sid).length != 0
                                console.log('ignoring duplicate onRemoteStreamAdded...')
                                return

                        # after remote stream has been added, wait for ice to become connected
                        # old code for compat with FF22 beta
                        el = $("<video autoplay='autoplay' style='display:none'/>").attr('id', 'largevideo_' + sid)
                        window.RTC.attachMediaStream(el, data.stream)

                        this.waitForRemoteVideo(el, sid)
                )

                $(document).bind('remotestreamremoved.jingle', =>
                        console.debug("NOT IMPLEMENTED remoteremoved")
                )
                $(document).bind('iceconnectionstatechange.jingle', (event, sid, sess) =>
                        console.debug('ice state for', sid, sess.peerconnection.iceConnectionState);
                        console.debug('sig state for', sid, sess.peerconnection.signalingState);
                        # works like charm, unfortunately only in chrome and FF nightly, not FF22 beta
                        """
                        if (sess.peerconnection.signalingState == 'stable' && sess.peerconnection.iceConnectionState == 'connected')
                                var el = $("<video autoplay='autoplay' style='display:none'/>").attr('id', 'largevideo_' + sid);
                                $(document).trigger('callactive.jingle', [el, sid]);
                                RTC.attachMediaStream(el, sess.remoteStream); // moving this before the trigger doesn't work in FF?!
                        }
                        """

                )


                $(document).bind('mediaready.jingle', (event, stream) =>
                        @jingle.localStream = stream
                        window.RTC.attachMediaStream($('#myvideo'), stream)
                        @jingle.getStunAndTurnCredentials()
                        console.debug("init rtc")
                        peer = @$scope.room_name + '/bob'
                        @jabber.connection.send($pres({to:peer}))
                        myroomjid = @$scope.room_name + '/' + Strophe.getNodeFromJid(@jabber.connection.jid)
                        console.debug(myroomjid)
                        @jingle.initiate(peer, myroomjid)

                )

                $(document).bind('error.jingle', (event, sid, error) =>
                        console.debug("JINGLE ERROR")
                        console.debug(sid)
                        console.debug(error)
                )

                $(document).bind('nostuncandidates.jingle', (event, sid) =>
                    console.warn('webrtc did not encounter stun candidates, NAT traversal will not work')
                )

        chat: =>
                getUserMediaWithConstraints(['audio', 'video'], '320')

class ChatRoomController
        constructor: (@$scope, @$rootScope, @jabber) ->
                @$scope.status = 0

                @$scope.room_topic = null
                @$scope.room = null

                @$scope.messages = []

                @$scope.occupants = {}

                @$scope.form =
                        message: null

                @$scope.connect = this.connect
                @$scope.sendMessage = this.sendMessage
                @$scope.getShortRoomName = this.getShortRoomName

                # When the jabber connection becomes ready
                @$scope.$on('jabber-connected', =>
                        nickname = Strophe.getNodeFromJid(@$rootScope.jabber_login.username)
                        console.debug("joining room... #{@$scope.room_name} with nickname #{nickname}")
                        @jabber.room_join(@$scope.room_name, nickname, this.onMessageReceived, this.onPresence, this.onRosterList)
                        @$scope.$broadcast('room-joined', @$scope.room_name)
                )

        getShortRoomName: =>
                ###
                # Return the short name, i.e. #test from the full room
                # name, i.e. #test@conference.foo.bar
                ###
                if not @$scope.room
                        return ""

                return Strophe.getNodeFromJid(@$scope.room.name)

        onPresence: (stanza, room) =>
                console.debug("presence in room changed..")
                @$scope.$apply(=>
                        @$scope.room = room
                )

                return true

        getVcard: (jid) =>
                return @$scope.occupants[jid].vcard

        onRosterList: (occupant_list) =>
                @$scope.occupants = {}
                console.debug("Received occupant list")

                @$scope.$apply( =>
                        for occupant_name of occupant_list
                                occupant = occupant_list[occupant_name]
                                # console.debug(occupant)
                                @$scope.occupants[occupant.jid] = {
                                        occupant: occupant
                                        vcard: null
                                }
                )


                for occupant_name of occupant_list
                        occupant = occupant_list[occupant_name]
                        @jabber.connection.vcard.get((stanza, vcard) =>
                                @$scope.$apply(=>
                                        vcard = @$scope.occupants[occupant.jid].vcard = {}
                                        photo = $(stanza).find("PHOTO")[0]
                                        vcard.photo_type = $(photo).children("TYPE").text()
                                        vcard.photo_data = $(photo).children("BINVAL").text()
                                )
                        ,
                        Strophe.getBareJidFromJid(occupant.jid)
                        )

        sendMessage: =>
                """
                On form submit, send message to room
                """
                @jabber.room_message(@$scope.room.name, @$scope.form.message)
                @$scope.form.message = ""

        onMessageReceived: (stanza, room) =>
                """
                When receiving a message from the chatroom
                """
                from = stanza.getAttribute('from')
                to = stanza.getAttribute('to')

                # Set topic?
                query = stanza.getElementsByTagName("subject")
                if query.length > 0
                        subject = Strophe.getText(query[0])
                        @$scope.$apply(=>
                                @$scope.room_topic = subject
                        )
                        return true

                # Chat msg?
                body = stanza.getElementsByTagName("body")[0]
                message = Strophe.getText(body)
                if message
                        @$scope.$apply(=>
                                @$scope.messages.push(
                                        from: Strophe.getResourceFromJid(from)
                                        text: message
                                )
                        )
                        return true

                return true


module.controller("ChatRoomController", ['$scope', '$rootScope', 'jabber', ChatRoomController])
module.controller("VideoChatController", ['$scope', 'jabber', VideoChatController])
module.controller("AlchemyController", ['$scope', 'jabber', AlchemyController])