require 'rubygems'
require 'tire'
require 'yajl/json_gem'

Tire.index 'applicationlogs' do
  delete
 # create
  store :title => 'One',   :tags => ['ruby']
  #store :title => 'texticle',   :tags => ['ruby', 'python']
  #store :title => 'Tencilie', :tags => ['java']
 # store :title => 'Four',  :tags => ['ruby', 'php']

  #refresh
end
s = Tire.search 'applicationlogs' do
      query do
        string 'title:T*'
      end
      end
      s.results.each do |document|
      puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
    end