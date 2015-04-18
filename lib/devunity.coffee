
Crypto = require 'crypto' #פלוץ גדול וענק
$ = require 'jquery'
{View} = require 'atom-space-pen-views'

{TextEditorView} = require 'atom-space-pen-views'

Firebase = require 'firebase'
Firepad = require './firepad-lib'


class SetupConfig
  constructor: ->

  setupUserNameDefault: ->
    hash = Crypto.createHash('md5').digest('base64');
    if !atom.config.get("devunity.username")
      atom.config.set("devunity.username", 'atom-'+hash.substring(0,5))


config = new SetupConfig()
config.setupUserNameDefault()

class ColabView extends View

  @content: (@codekey, @filename) ->
    #console.log(@codekey)
    @div class: 'devunity devunitypanel panel panel-bottom devunity_'+@codekey+'',outlet: @codekey , =>
      @div
        style: 'padding:10px;border-bottom:1px solid #ef4423'
        =>
          @div '[x] Stop collaboration',id: 'stopCollab', class: ' pull-right',style:'cursor:pointer;color:#ef4423'
          @div class: 'pull-left', =>
            @span '{dev',style:''
            @span 'un',style:'color:#ef4423'
            @span 'ity}',style:'padding-right:5px'
          @a 'Collaborating on '+@filename+' at devunity.com/c/'+@codekey, href: 'http://devunity.com/c/'+@codekey

  show: ->

    atom.workspace.addBottomPanel(item: this)

module.exports =
class DevunityView extends View
  @activate: -> new DevunityView

  @content: ->
    @div class: 'devunity overlay from-top mini', =>
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'message', outlet: 'message'

  detaching: false

  initialize: ->

    atom.commands.add 'atom-workspace', 'devunity:start', => @start()
    atom.commands.add 'atom-workspace', 'devunity:stop', => @stop()
    atom.commands.add 'atom-workspace', 'devunity:stopAll', => @stopAll()

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

    $('.devunitypanel').hide()
    if @pad
      if @pad.devunitycodeid
        $('.devunity_'+@pad.devunitycodeid).show()


  start: ->

    if editor = atom.workspace.getActiveTextEditor()

      code = atom.workspace.getActiveTextEditor().getText()
      language = @getLanguage()

      $.ajax
        url:'http://www.devunity.com/c/new'
        type:'POST'
        data:{'code':code,'language':language}
        dataType:'json'
        crossDomain: true
        success: (response) =>
          if response
            @confirm(response.url)


  confirm: (codeurl) ->
    @detach()

    codekey = codeurl.split "="

    @ref = new Firebase('https://devunityio.firebaseio.com/c/'+codekey[1]);

    editor = atom.workspace.getActiveTextEditor()
    editor.devunitycodeid = codekey[1]

    hash = Crypto.createHash('md5').digest('base64');

    @coderef = @ref.child('code');

    @coderef.once 'value', (snapshot) =>
        options = {sv_: Firebase.ServerValue.TIMESTAMP}


        if !snapshot.val().code && editor.getText() != ''
          options.overwrite = true
        else
          editor.setText ''
        @pad = Firepad.fromAtom @ref, editor, options
        @pad.setUserId('@'+atom.config.get('devunity.username'));

        @view = new ColabView(codekey[1],@getFilename())
        @view.show()

        $('#stopCollab').on 'click', =>
          @stop()
        #@initStatistics

        #Lets add the comment stating where the collaboration is being done online
        #comment = @getColabComment(@getLanguage(),codekey[1])
        #editor.setText comment+editor.getText()

  getFilename: ->
    filepath = atom.workspace.getActiveTextEditor().getPath()
    if(filepath)
      filename = filepath.substring(filepath.lastIndexOf("/")+1)
      return filename
    else
      return 'untitled'

  getLanguage: ->

    filepath = atom.workspace.getActiveTextEditor().getPath()
    if(!filepath)
      language = 'javascript'
    else
      language = filepath.substring(filepath.lastIndexOf(".")+1)
      if(!language)
        language = 'javascript'

    return language

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
    @editor = atom.workspace.getActiveTextEditor()
    @ref = new Firebase('https://devunityio.firebaseio.com/c/'+codekey[1]);
    @stats = @ref.child('statistics')

		#@editor.on 'change', =>

			#console.log('Change of editor');

			#@stats.update({lines:editor.session.doc.getLength()});

			#@stats.update({length:editor.session.getValue().length});


		#@editor.on 'copy', =>

			#console.log('copy');


		#	if(!Collaborate.currentObject.statistics.copy) { Collaborate.currentObject.statistics.copy = 0 };

		  #@stats.update({copy:Collaborate.currentObject.statistics.copy+1});



		#@editor.on 'focus', =>

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
    if @pad.firepad
      @pad.firepad.dispose()
      $('.devunity_'+@pad.devunitycodeid).detach()
      delete @pad.devunitycodeid

  stop: ->

    @pad = atom.workspace.getActiveTextEditor()
    @stopItem(@pad)

  stopAll: ->
    editors = atom.workspace.getEditors()
    for i,d in editors
      @stopItem(i)
