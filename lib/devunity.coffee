
Crypto = require 'crypto' #פלוץ גדול וענק
$ = require 'jquery'
{View} = require 'atom-space-pen-views'

{TextEditorView} = require 'atom-space-pen-views'

Firebase = require 'firebase'
Firepad = require './firepad-lib'


class Utils
  removeChat: (id) ->
    $('#'+id).remove()


class StartFromKeyView extends View
  @content: ->
    @div class:'devunity devunitypanel devunitystartfromkey',id:'devunitystartfromkey',=>
      @div 'Enter your session key below and hit start',class:'sendchattext'
      @subview 'sessionkey', new TextEditorView(mini: true)
      @button 'Start', class:'chatbutton',type:'submit',id:'startsession'
      @span 'Cancel',class:'floatright',id:'startkeyclose'

    detaching: false

  closeStartkey: ->
    $('#devunitystartfromkey').parent().remove()

  @detach: ->
    return unless @hasParent()
    @detaching = true
    @sessionkey.setText('')
    super
    @detaching = false
    @closeChat()

  show: ->
    atom.workspace.open()
      .then ->
        @removepanel = atom.workspace.addModalPanel(item:this)
        @sessionkey.focus()
        $('#startsession').on 'click', =>
          @startSessionFromKey()

        $('#startkeyclose').on 'click', =>
          @closeStartkey()

  open: ->
    this.show()

  startSessionFromKey: ->
    #b3e02e312f277862ea7f4a8eb82e97

    #@confirm("/hello?codekey="+@sessionkey.getText(),'Anonymous')



class ShowSessionDetails extends View
  @content: (codekey) ->
    @div class:'devunity devunitypanel devunitysessiondetails',id:'devunitysessiondetails',=>
      @div 'This is your current session details',class:'sendchattext'
      @div 'Session on web',class:'sendchattext'
      @subview 'sessionurl', new TextEditorView(mini: true)
      @a 'Open in browser', class:'floatright', href: 'http://devunity.com/c/'+codekey,target:"_blank"
      @hr
      @div 'Session key',class:'sendchattext'
      @subview 'sessionkey', new TextEditorView(mini: true)
      @span 'Close', class:'detailsclose',id:'detailsclose'

    detaching: false

  closeDetails: ->
    $('#devunitysessiondetails').parent().remove()

  @detach: ->
    return unless @hasParent()
    @detaching = true
    @sessionkey.setText('')
    super
    @detaching = false
    @closeChat()

  show: (codekey) ->
    @sessionkey.setText(codekey)
    @sessionurl.setText('http://www.devunity.com/c/'+codekey);
    @removepanel = atom.workspace.addModalPanel(item:this)
    @sessionkey.focus()

    $('#detailsclose').on 'click', =>
      @closeDetails()

class SetupConfig
  constructor: ->

  setupApiDefault: ->
    if !atom.config.get("devunity.apikey") || atom.config.get("devunity.apikey") == ''
      #user is anonymous until proven otherwise :)
      atom.config.set("devunity.apikey", 'anonymous')

class ChatSendView extends View

  @content: ->
    @div class: 'devunity devunitypanel devunitychatbox',id:'devunitychatbox',=>
      @div 'Send a chat message',class:'sendchattext'
      #@input class:'chatinput', type:'text',id:'chatinput'
      @subview 'chatinput', new TextEditorView(mini: true,placeholderText:'Enter your chat message')
      @button 'Send', class:'chatbutton',type:'submit',id:'chatbutton'
      @span 'Cancel', class:'chatcancel',id:'chatcancel'

  detaching: false

  detach: ->
    return unless @hasParent()
    @detaching = true
    @chatinput.setText('')
    super
    @detaching = false
    @closeChat()

  sendChat: ->
    @pad = atom.workspace.getActiveTextEditor()
    if @pad.firepad
      console.log(@pad.firepad)
      @codekey = @pad.devunitycodeid
      @text = @chatinput.getText()
      console.log(@codekey)
      @chatref = new Firebase('https://devunityio.firebaseio.com/c/'+@codekey+'/chat');
      @chatref.push({user: @pad.firepad.firebaseAdapter_.userId_ ,text:@text});
      $('#chatinput').empty()
      @closeChat()

  closeChat: ->
    $('#devunitychatbox').parent().remove()

  show: ->
    @removepanel = atom.workspace.addModalPanel(item:this)
    @chatinput.focus()

    $('#chatbutton').on 'click', =>
      @sendChat()

    $('#chatcancel').on 'click', =>
      @closeChat()


class ChatViewItem extends View
  @constructure: (username,text,chatid) ->
    @content(username,text,chatid)
  @content: (username,text,chatid) ->

    @div class: 'devunity devunitypanel panel panel-bottom', id: chatid, =>
      @div
        class:'chatitemwrapper'
        =>
          @div class: 'pull-left', =>
            @span '{dev',style:''
            @span 'un',style:'color:#ef4423'
            @span 'ity:chat}',style:'padding-right:5px'
          @div class: 'pull-left',style:'margin-left:5px', =>
            @span ''+username+': '+text

  removechat: ->
    $('#'+this.attr('id')).fadeOut ->
      #$(this).remove()
      $(this).parent().remove()

  show: ->
    @removepanel = atom.workspace.addBottomPanel(item:this)
    console.log(this.attr('id'));
    setTimeout =>
     @removechat()
    , 3000

class ColabView extends View

  @content: (@codekey, @filename) ->
    #console.log(@codekey)
    @div class: 'devunity devunitypanel inline-block devunity_'+@codekey+'',outlet: @codekey , =>
      @div
        class: 'colabdetailsrow'
        =>
          @div '[x] Stop',id: 'stopCollab', class: 'stopcollab pull-right'
          @div '[C] Send chat',id: 'openchat', class:'openchattext pull-right'
          @div '[D] Details',id: 'details', class: 'details pull-right'
          @div id: 'readonly', class: 'readonly pull-right', =>
            @label 'Read only ', =>
              @input type: 'checkbox',id:'readonlycheckbox',style:'margin-right:3px;'
          @div id: 'users', class: ' pull-right'
          @div class: 'pull-left', =>
            @span '{dev',style:''
            @span 'un',style:'color:#ef4423'
            @span 'ity}'
          @div class: 'pull-left', style:'padding-left:5px;padding-right:5px',=>
            @a 'Open in web', href: 'http://devunity.com/c/'+@codekey,target:"_blank"

  show: ->
    statusbar = new StatusBarManager()
    statusbar.addRightTile(item: this, priority: 1000)

    #atom.workspace.addBottomPanel(item: this)

class DevunityView extends View
  @activate: -> new DevunityView

  @content: ->
    @div class: 'devunity devunitypanel panel panel-bottom devunity_'+@codekey+'',outlet: @codekey , =>
      @div

  detaching: false

  initialize: ->

    config = new SetupConfig()
    config.setupApiDefault()

    atom.commands.add 'atom-workspace', 'devunity:start', => @start()
    atom.commands.add 'atom-workspace', 'devunity:stop', => @stop()
    atom.commands.add 'atom-workspace', 'devunity:stopAll', => @stopAll()

    #atom.commands.add 'atom-workspace', 'devunity:startLive', => @startLive()
    #atom.commands.add 'atom-workspace', 'devunity:stopLive', => @stopLive()

    #atom.commands.add 'atom-workspace', 'devunity:startfromkey', => @startFromKey()


    @stopobserving = atom.workspace.observeActivePaneItem (pad) =>
      @managePanes(pad)

    @stopobservepanes = atom.workspace.onDidDestroyPaneItem (event) =>
      if(event.item.firepad)
          @stopItem(event.item)

    @detach()

  detach: ->

    @detaching = true
    super
    @detaching = false

  managePanes: (@pad) ->

    @manageLive(@pad)

    $('.devunitypanel').hide()
    if @pad
      if @pad.devunitycodeid
        $('.devunity_'+@pad.devunitycodeid).show()

  startFromKey: ->
    @startkey = new StartFromKeyView()
    @startkey.open()

  startLive: ->

    #turn on live sessions
    #Grab a playlist ID and save it.

    $.ajax
      url:'http://devunity.com/playlist/new',
      type:'GET'
      dataType:'json'
      crossDomain: true
      success: (response) =>
        if response
          console.log(response)
          atom.config.set("devunity.livekey",response.key);

  manageLive: (@pad) ->

    if atom.config.get("devunity.livekey")
      console.log('We are here!');
      #lets open a new session for this pad. dont do anything if there is an existing one.
      if !@pad.firepad
        @start()

      #add the current pad id to the playlist and broadcast it.
      @playlist = new Firebase('https://devunityio.firebaseio.com/p/'+atom.config.get("devunity.livekey"));
      @playlistsessions = @playlist.child('sessions');
      @playlistsessions.push(@pad.devunitycodeid);

  start: ->

    if editor = atom.workspace.getActiveTextEditor()

      code = atom.workspace.getActiveTextEditor().getText()
      language = @getLanguage()

      $.ajax
        url:'http://devunity.com/c/new/'+atom.config.get('devunity.apikey')
        type:'POST'
        data:{'code':code,'language':language}
        dataType:'json'
        crossDomain: true
        success: (response) =>
          if response
            if atom.config.get('devunity.apikey') == 'anonymous'
              alert('Please note, this session was created as anonymous, to get your own user head over to devunity.com')
            @activateSession(response.url,response.username)

  activateSession: (codeurl,username) ->
    @detach()

    codekey = codeurl.split "="
    @ref = new Firebase('https://devunityio.firebaseio.com/c/'+codekey[1]);

    editor = atom.workspace.getActiveTextEditor()
    editor.devunitycodeid = codekey[1]

    hash = Crypto.createHash('md5').digest('base64');

    @coderef = @ref.child('code');
    @userref = @ref.child('users');
    @chatref = @ref.child('chat');
    @readonlyref = @ref.child('readonly');

    @coderef.once 'value', (snapshot) =>
        if snapshot
          options = {sv_: Firebase.ServerValue.TIMESTAMP}

          #console.log(snapshot.val())

          if editor.getText() != ''
            options.overwrite = true
          else
            editor.setText ''
          @pad = Firepad.fromAtom @ref, editor, options
          @pad.setUserId(username+' from atom');

          @view = new ColabView(codekey[1],@getFilename())
          @view.show()

          #stop collab button
          $('#stopCollab').on 'click', =>
            @stop()

          $('#openchat').on 'click', =>
            @openChatInput()

          $('#details').on 'click', =>
            @detailView = new ShowSessionDetails(codekey[1])
            @detailView.show(codekey[1])

          @initStatistics()

          #read only button
          $('#readonlycheckbox').on 'click', =>
            @readonlyref.set($('#readonlycheckbox')[0].checked);

          #Lets add the comment stating where the collaboration is being done online
          #comment = @getColabComment(@getLanguage(),codekey[1])
          #editor.setText comment+editor.getText()

          @readonlyref.on 'value',(snapshot) =>
            if snapshot
              $('#readonlycheckbox')[0].checked = snapshot.val()

          @chatref.on 'child_added', (snapshot) =>
            if snapshot
              chattext = snapshot.val().text
              chatuser = snapshot.val().user
              console.log('chat message!');
              if chattext && chatuser
                @viewchat = new ChatViewItem(chatuser,chattext,snapshot.name())
                @viewchat.show()

          @userref.on 'child_added', (snapshot) =>
            #console.log(snapshot)
            if snapshot
              user = snapshot.val();
              connecteduser = snapshot.name()
              connectedusercolor = snapshot.val().color;
              if $('#users') && connecteduser && connectedusercolor
                $('#users').append($("<div style='margin-right:5px;float:right'/>").attr("id", connectedusercolor.substr(1)));
                $('#'+connectedusercolor.substr(1)).css('color',connectedusercolor);
                $('#'+connectedusercolor.substr(1)).text(connecteduser);

          @userref.on 'child_removed', (snapshot) =>
            if snapshot
              user = snapshot.val();
              connecteduser = snapshot.name()
              connectedusercolor = snapshot.val().color;
              if user && connecteduser && connectedusercolor
                $('#'+connectedusercolor.substr(1)).remove();

  openChatInput: ->

    @chatinput = new ChatSendView()
    @chatinput.show()

  getFilename: ->
    filepath = atom.workspace.getActiveTextEditor().getPath()
    if(filepath)
      filename = filepath.substring(filepath.lastIndexOf("/")+1)
      return filename
    else
      return 'untitled'

  getLanguage: ->

    #filepath = atom.workspace.getActiveTextEditor().getPath()
    #if(!filepath)
    #  language = 'javascript'
    #else
    #  language = filepath.substring(filepath.lastIndexOf(".")+1)
    #  if(!language)
    #    language = 'javascript'

    editor = atom.workspace.getActiveEditor()
    grammar = editor.getGrammar()
    language = grammar.name;
    console.log(grammar)
    if language == 'Null Grammar'
      language = 'javascript'

    return language.toLowerCase()

  getColabComment: (fileextension,codekey) ->

    comment = ''
    switch fileextension
      when 'py'
        comment +='\n# Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='# To end collaboration click Packages > Devunity > stop\n'

      when 'php'
        comment += '\n// Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='// To end collaboration click Packages > Devunity > stop\n'

      when 'html'
        comment +='\n<!-- Collaboration url: http://devunity.com/c/'+codekey+'-->\n'
        comment +='<!-- To end collaboration click Packages > Devunity > stop\n'

      when 'js'
        comment +='\n// Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='// To end collaboration click Packages > Devunity > stop\n'

      when 'javascript'
        comment +='\n// Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='// To end collaboration click Packages > Devunity > stop\n'

      when 'coffee'
        comment +='\n# Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='# To end collaboration click Packages > Devunity > stop\n'

      when 'c'
        comment +='\n/* Collaboration url: http://devunity.com/c/'+codekey+' */\n'
        comment +='/* To end collaboration click Packages > Devunity > stop */\n'

      when 'css'
        comment +='\n/* Collaboration url: http://devunity.com/c/'+codekey+' */\n'
        comment +='/* To end collaboration click Packages > Devunity > stop */\n'

      when 'h'
        comment +='\n/* Collaboration url: http://devunity.com/c/'+codekey+' */\n'
        comment +='/* To end collaboration click Packages > Devunity > stop */\n'

      when 'jsp'
        comment +='\n/* Collaboration url: http://devunity.com/c/'+codekey+' */\n'
        comment +='/* To end collaboration click Packages > Devunity > stop */\n'

      when 'txt'
        comment +='\n# Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='# To end collaboration click Packages > Devunity > stop */\n'

      when 'pl'
        comment +='\n# Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='# To end collaboration click Packages > Devunity > stop\n'

      when 'rc'
        comment +='\n# Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='# To end collaboration click Packages > Devunity > stop\n'

      else # default, could also just omit condition or 'if True'
        comment +='\n# Collaboration url: http://devunity.com/c/'+codekey+'\n'
        comment +='# To end collaboration click Packages > Devunity > stop\n'
    return comment


  initStatistics: ->

		#Lets collect some statistics
    pad = atom.workspace.getActiveTextEditor()
    @ref = new Firebase('https://devunityio.firebaseio.com/c/'+@pad.devunitycodeid);
    stats = @ref.child('statistics')

    pad.onDidChange(->
			      stats.update({lines:pad.getLineCount()});
			      stats.update({length:pad.getText().length});
        );




		#pad.on 'copy', =>

			#console.log('copy');


		#	if(!Collaborate.currentObject.statistics.copy) { Collaborate.currentObject.statistics.copy = 0 };

		  #@stats.update({copy:Collaborate.currentObject.statistics.copy+1});



     #$(window).on 'focus', (event) =>

			#console.log('focus');

			#Collaborate.GetCurrentCodeObject();

			#if(!Collaborate.currentObject.statistics.focus) { Collaborate.currentObject.statistics.focus = 0 };

			#Collaborate.statistics.update({focus:Collaborate.currentObject.statistics.focus+1});


		#@editor.on 'paste', =>

			#console.log('paste');

			#Collaborate.GetCurrentCodeObject();

			#if(!Collaborate.currentObject.statistics.paste) { Collaborate.currentObject.statistics.paste = 0 };

			#Collaborate.statistics.update({paste:Collaborate.currentObject.statistics.paste+1});

		#@editor.on 'blur', =>

			#console.log('blur');

			#Collaborate.GetCurrentCodeObject();

			#if(!Collaborate.currentObject.statistics.blur) { Collaborate.currentObject.statistics.blur = 0 };

			#Collaborate.statistics.update({blur:Collaborate.currentObject.statistics.blur+1});


  stopItem: (@pad) ->

    console.log('Stop collab!')
    $('#stopCollab').detach()
    selections = @pad.getSelections()
    for i,d in selections
      i.clear()

    decorations = @pad.getDecorations()
    for i,d in decorations
      i.destroy()

    if @pad.firepad
      @pad.firepad.dispose()
      $('.devunity_'+@pad.devunitycodeid).detach()
      delete @pad.devunitycodeid

  stop: ->
    @pad = atom.workspace.getActiveTextEditor()
    @stopItem(@pad)

  stopAll: ->
    atom.config.unset("devunity.livekey");
    editors = atom.workspace.getEditors()
    for i,d in editors
      @stopItem(i)

#Lets start everything!

class StatusBarManager
  instance = null

  constructor: (statusBar)->
    if instance
      return instance
    else
      instance = statusBar

module.exports =
  activate: (state) ->
    devunity = new DevunityView()

  consumeStatusBar: (statusBar) ->
    statusmanager = new StatusBarManager(statusBar)
