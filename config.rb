set :css_dir, 'css'
set :js_dir, 'js'
set :images_dir, 'img'
set :partials_dir, 'partials'

set :markdown_engine, :redcarpet
set :markdown, fenced_code_blocks: true, smartypants: true

compass_config do |config|
  config.output_style = :compact
end

require 'slim'
Slim::Engine.disable_option_validator!
require 'builder'
require 'better_errors'

activate :i18n, mount_at_root: :fr
activate :directory_indexes
activate :syntax
activate :protect_emails
# activate :automatic_image_sizes

helpers do
  def card_image_url(source)
    path = image_path("#{source}.jpg")
    path = path[3..-1] if path.start_with? '..'
    "https://bobmaerten.eu/#{path}"
  end
end

activate :blog do |blog|
  blog.name = 'blog'
  blog.prefix = 'blog'
  blog.permalink = ':title.html'
  blog.sources = ':year-:month-:day-:title.html'
  blog.taglink = 'tags/:tag.html'
  blog.layout = 'post'
  blog.summary_separator = /READMORE/
  blog.new_article_template = 'blog_post.tmpl'
  # blog.summary_length = 250
  # blog.year_link = ':year.html'
  # blog.month_link = ':year/:month.html'
  # blog.day_link = ':year/:month/:day.html'
  blog.default_extension = '.markdown'
  # blog.new_article_template = 'blog_article.tmpl'
  blog.tag_template = 'tag.html'
  # blog.calendar_template = 'calendar.html'
  blog.paginate = true
  blog.per_page = 5
  blog.page_link = 'page/:num'
end

# activate :google_analytics do |ga|
#   ga.tracking_id = data.settings.google_analytics.tracking_code
#   ga.anonymize_ip = true
#   ga.debug = false
#   ga.development = false
#   ga.minify = true
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page '/path/to/file.html', :layout => false
page '/404.html', directory_index: false
page '/about.html', directory_index: false
page '/atom.xml',    layout: false
page '/sitemap.xml', layout: false
page 'blog/index.html', proxy: '/blog.html'
page 'index.html', proxy: '/blog.html'

# With alternative layout
# page '/path/to/file.html', :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page '/admin/*'
# end

# Proxy pages (https://middlemanapp.com/advanced/dynamic_pages/)
# proxy '/this-page-has-no-template.html', '/template-file.html', locals: {
#  which_fake_page: 'Rendering a fake page with a local variable' }

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

# Build-specific configuration
configure :build do
  activate :favicon_maker do |f|
    f.template_dir  = File.join(root, 'source')
    f.output_dir    = File.join(root, 'build')
    f.icons = {
      'favicon_base.png' => [
        { icon: 'chrome-touch-icon-192x192.png' },
        { icon: 'apple-touch-icon.png', size: '152x152' },
        { icon: 'ms-touch-icon-144x144-precomposed.png', size: '144x144' },
        { icon: 'favicon-196x196.png' },
        { icon: 'favicon-160x160.png' },
        { icon: 'favicon-96x96.png' },
        { icon: 'favicon-32x32.png' },
        { icon: 'favicon-16x16.png' },
        { icon: 'favicon.ico', size: '64x64,32x32,24x24,16x16' }
      ]
    }
  end
  activate :minify_html
  activate :minify_css
  activate :minify_javascript
  activate :asset_hash
  activate :relative_assets
  set :relative_links, true
  activate :gzip
  activate :sitemap, hostname: data.settings.site.url
  activate :imageoptim do |options|
    options.manifest = false
    options.pngout = false
    options.svgo   = false
  end
end
