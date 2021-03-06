((context, definition) ->
  if 'function' is typeof require and
     typeof exports is typeof module
    return module.exports = definition
  return context.CoffeeTemplates = definition
)(@, (->
  # abbreviation for typeof, because we use it a lot
  y=(v)->(typeof v)[0]

  # constructor
  C = (o)-> # options
    o = o or {}
    o.indent = (o.format or '') and (o.indent or '  ')
    o.newline = (o.format or '') and (o.newline or "\n")
    o.globals = o.globals or {} # global scope of coffee template function
    # only non-false need be declared
    #o.escape = o.escape or false # automatically escape special characters
    #o.special = o.special or {} # special characters to be escaped
    #o.format = o.format or false # add whitespace to output
    #o.handlebars = o.handlebars or false # render {{#block}}{{/block}} instead of {{block}}{{/block}}

    # html5-only by default; add older crap via configuration for special cases
    o.doctype = o.doctype or { '5': '<!doctype html>' }
    o.tags = o.tags or 'a abbr address article aside audio b bdi bdo blockquote body button canvas caption cite code colgroup command data datagrid datalist dd del details dfn div dl dt em embed eventsource fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins kbd keygen label legend li mark map menu meter nav noscript object ol optgroup option output p pre progress q ruby rp rt s samp script section select small source span strong style sub summary sup table tbody td textarea tfoot th thead time title tr track u ul var video wbr'.split ' '
    o.atags = o.atags or 'area base br col hr img input link meta param'.split ' '
    o.special = o.special or { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }
    @o = o
    return

  # main render function
  # formerly mini-coffeecup
  C.prototype.render = (tf, i) -> # template function, instance variables
    t='' # template
    l=0  # indentation level
    o=@o # options (without requirement of `this.` context)
    indent=((x)->->(new Array(l)).join x)(o.indent) # indentation function
    g=o.globals # globals abbreviated
    g.render=(tf)=>@render tf, i
    g.tag=(a,b,c,d)->->
      # a # prefix
      # b # attributes array join function
      # c # after attributes
      # d # suffix
      e=arguments
      f={} # attributes
      # h # content (string, or function that returns a string)
      l++ # indentation level
      s='' # interface signature
      # x # interation integer
      for x of e
        e[x] = ''+e[x] if y(e[x]) is 'n' # convert any numbers to strings
        s+=y e[x] # (string, object, function) == 'sof'
      if s is 'sof' or s is 'sos' or s is 'so' or s is 'sf' or s is 'ss'
        # convert string to attributes object
        e[0].replace /([#.][\w\d-_]+)/g, (m) ->
          `var k='class'`
          (m[0] is '.') and f[k] = (f[k] or '') + (if f[k] then ' ' else '') + m.substr 1
          (m[0] is '#') and f.id = m.substr 1
          return
      (s is 'of' or s is 'os' or s is 'o') and f = e[0]
      (s is 'f' or s is 's') and h = e[0]
      if s is 'sof' or s is 'sos' or s is 'so'
        for x of e[1]
          f[x] = e[1][x]
        h = e[2]
      (s is 'of' or s is 'os' or s is 'sf' or s is 'ss') and h = e[1]
      f = if y(b) is 'f' then b f else '' # compile attributes object with given attributes join function

      if y(h) is 'f'
        # this += is unexpectedly magical:
        # it stores the value of t before it evaluates the closure,
        # inside the closure, t is reset to '',
        # but then when the function returns a string,
        # its concatenated back onto the original t!
        # string concatenation is perhaps one of the few
        # cases where i can get away with this...
        t+=(->
          t = ''
          r=h.call i
          if y(r) is 's' and r isnt t then t += r # allow tag functions to return a string and have it appended
          t = o.newline+t+indent() if t isnt ''
          t = indent()+a+f+c+t+d+o.newline
        )()
      else
        t += indent()+a+f+c+(if y(h) is 'u' then '' else if o.escape then g.h(h) else h)+d+o.newline
      l--
    g.block = (s,f) ->
      if typeof f is 'undefined' # if no function provided, return string only (e.g. for inline use in arguments)
        return '{{'+(if o.handlebars then '#' else '')+s+', (s)}}{{s}}{{/'+s.split(`/ +/`)[0]+'}}'
      # otherwise, append to template and return nothing
      g.tag('{{'+(if o.handlebars then '#' else '')+s, null, '}}', '{{/'+(s.split(`/ +/`)[0])+'}}')(f)
      return
    g.h = (s) -> (''+s).replace /[&<>"']/g, (c) -> o.special[c] or c # escape special characters
    g.text = (s) -> t += if o.escape then g.h(s) else s
    g.literal = (s) -> t += s
    g.coffeescript = (f) -> g.script (''+f).replace(/^function \(\) ?\{\s*(return\s*)?/,'').replace(/\s*\}$/,'')
    g.doctype = (v) -> t = o.doctype[v or 5] + o.newline + t
    g.comment = (s,f) -> g.tag('<!--'+s, null, '', '-->')(f)
    g.ie = (s,f) -> g.tag('<!--[if '+s+']>', null, '', '<![endif]-->')(f)
    g.content_for = (s,f) -> g.block 'content_for '+JSON.stringify(s), f
    g.yields = (s) -> g.block 'yields '+JSON.stringify(s), ->
    g.partial = (s, args) -> g.block 'partial '+JSON.stringify(s)+(if args then ', '+args else ''), ->
    g.layout = (s) -> g.block 'layout '+JSON.stringify(s), ->
    atts = (a) ->
      z = ''
      for k of a
        z += if y(a[k]) isnt 'b' then ' '+k+'="'+(if o.escape then g.h(a[k]) else a[k])+'"' else if a[k] then ' ' + k else ''
      return z
    for x of o.tags
      g[o.tags[x]] = g.tag '<'+o.tags[x], atts, '>', '</'+o.tags[x]+'>'
    for x of o.atags
      g[o.atags[x]] = g.tag '<'+o.atags[x], atts, '/>', ''
    (Function 'g', '_i', 'with(g){('+tf+').call(_i)}')(g, i)
    return t

  # main compile function
  # formerly mini-handlebars
  C.compile = (t, o, wrap=true) ->
    o = o or {}
    lvl = 1; toks = []; tokm = {}
    t.replace `/\{\{([\/#]{0,2}[^ }]+)( [^}]+)?\}\}/g`, ->
      a = arguments; cf = a[1][0] is '/' # closing block/function
      tok =
        s: a[0] # matched string
        b: b = (typeof a[2] is 'string' and a[2] isnt '') # block/function
        a: (b and a[2]) or '' # block/function arguments
        v: b is cf # variable
        n: if b is cf then a[1] else if a[1].substr(0,2) is '/#' then a[1].slice(2) else if a[1][0] is '/' or a[1][0] is '#' then a[1].slice(1) else a[1] # name
        l: l = (b is cf and lvl) or (b and lvl++) or (cf and --lvl) # level
        x: a[3] # x-coordinate character position
      if tok.n is 'if' then tok.n = '__if'
      k=l+'.'+tok.n
      return !!((l is 1) and
        (cf and toks[tokm[k]].o = tok) or
        ((tok.v or tok.b) and tokm[k] = toks.push(tok)-1) # map token keys to token array indicies
      ) or a[0]

    if toks.length
      a = []
      push=(m,s)-> # token collection
        if a.length%2 is m or a.length < 1 # if its not empty and new or not like the previous
          a.push s # push it
        else # otherwise, its like the previous
          a[a.length-1] += s # append it
        return
      #a=0 # template start
      b=0 # cursor position; x-coordinate offset
      g=t.length-1 # template end
      for k of toks when toks[k].l is 1
        c=toks[k].x # token start
        d=c+toks[k].s.length # token end
        push 0, t.substr b, c-b # push chars before token as string
        if toks[k].v # process variable
          push 1, toks[k].n # push token as js literal
          b=d # move cursor to token end
        else if toks[k].b # process block/function
          e=toks[k].o.x # token pair start
          f=e+toks[k].o.s.length # token pair end
          # parse function arguments list and callback arguments list
          toks[k].a = toks[k].a.replace(`/(^ *| *$)/`, '').replace(`/, *\((.+)\) *$/`, ->
            toks[k].c = arguments[1].split(`/, */`).join(',')
            '').split(`/, */`).join(',').replace(/([\w\d]+):(.+)$/, '{$1:$2}')
          # push token as js literal function call
          ff=t.substr(d,e-d)
          push 1, 'w('+toks[k].n+',['+(if toks[k].a then toks[k].a+(if ff then ',' else '') else '')+(if ff then 'function('+(toks[k].c or '')+'){o+='+C.compile(ff, o, false)+'}' else '')+'])'
          b=f # move cursor to token pair end
      if g-b # some strings remain at template end
        push 0, t.substr b, g-b+1 # push chars from cursor to template end as string
      t = ''
      for i of a when a.hasOwnProperty(i) and a[i] isnt ''
        t += (if t then '+' else '') +
          if i%2
            a[i]
          else # odd indicies are stringified to become literals
            JSON.stringify a[i]
    else
      t = JSON.stringify t
    if wrap
      return Function 'g', 'with(g||{}){var o="",w=function(f,a){o="";f.apply({},a);return o};return '+t+'}'
    else return t

  C.compileAll=(a,o)->
    o = o or {}
    for k of a
      a[k] = C.compile a[k], o, false
    f = 'var o="";'
    unless o.omit_helpers
      f += 'var c={},p="partial",l="layout",content_for=function(s,f){c[s]=c[s]||[];c[s].push(f)},yields=function(s){while(c[s]&&c[s].length)c[s].pop()()},z=function(g){var y=o,n;if(g&&g.l&&(n=g.l.pop())){content_for("content",function(){o+=y});o="";g[p](n,g);}},__if=function(v,f){v&&v.length!==0&&f()},each=function(o,f){for (var k in o)o.hasOwnProperty(k)&&f.apply(o[k],[k,o[k]])};g=g||{};g.l=[g[l]];g[l]=function(n){g.l.push(n)};g[p]=function(n,e){e=e||{};for(var k in g){e[k]=e[k]||g[k]};var q=g.l;g.l=[];with(e){'
    else
      f += 'with(g){'
    f += 'var w=function(f,a){o="";f.apply({},a);return o},t={\n'
    for k, t of a
      f += JSON.stringify(k)+':function(){return '+a[k].replace('</script>','<"+"/script>')+"},\n"
    f += '}};o+=t[n]();'
    unless o.omit_helpers
      f+='z(g);g.l=q};g[p](n,g);z(g);'
    return Function 'n', 'g', f+'return o'

  return C
)())
