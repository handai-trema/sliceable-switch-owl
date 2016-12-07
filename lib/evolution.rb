# Finds shortest path.
class Evolution
  # Graph node
  class Node
    attr_reader :name
    attr_reader :neighbors
    attr_reader :distance
    attr_reader :prev

    def initialize(name, neighbors)
      @name = name
      @neighbors = neighbors
      @distance = 100_000
      @prev = nil
    end

    def maybe_update_distance_and_prev(min_node)
      new_distance = min_node.distance + 1
      return if new_distance > @distance
      @distance = new_distance
      @prev = min_node
    end

    def distance=(new_distance)
      fail if new_distance < 0
      @distance = new_distance
    end

    def <=>(other)
      @distance <=> other.distance
    end
  end

  # Sorted list.
  # TODO: Replace with heap.
  class SortedArray
    def initialize(array)
      @array = []
      array.each { |each| @array << each }
      @array.sort!
    end

    def method_missing(method, *args)
      result = @array.__send__ method, *args
      @array.sort!
      result
    end
  end

  def initialize(graph)
    @all = graph.map { |name, neighbors| Node.new(name, neighbors) }
    @unvisited = SortedArray.new(@all)
  end

  #runは重複しないよう、上で消しているので注意

  def run(start,goal)
#    print "bbbb"
#last_node=@all.select { |n| n.name == path_c.last }
#maybe_update_neighbors_of(last_node)
#print start
#print goal
@path = Array.new
start_node=@all.select { |n| n.name == start }
    @path.push(start_node[0])
    #node_i = start
#    print "ccc"
    better_path(start,goal)
#    print "aaaa"
@answer = Array.new
answer(@path.shift) until @path.empty?
return @answer
#print @path 
    return @path 
  end

  private

  def maybe_update_neighbors_of(min_node)
    min_node.neighbors.each do |each|
      find(each, @all).maybe_update_distance_and_prev(min_node)
    end
  end

  def answer(each)
    @answer.push(each.name)
  end

  # This method smells of :reek:FeatureEnvy but ignores them
  # This method smells of :reek:DuplicateMethodCall but ignores them
  def path_to(goal)
    [find(goal, @all)].tap do |result|
      result.unshift result.first.prev while result.first.prev
    end.map(&:name)
  end

  def find(name, list)
    found = list.find { |each| each.name == name }
    fail "Node #{name.inspect} not found" unless found
    found
  end

 def maybe_update_neighbors_of(min_node)
#print "mintest"
#    print min_node
#print "mintest2"
#    print min_node.neighbors
  end




# 追記

#注意
generation_number=100
@min_length = 1000




  def better_path(start,goal)
    #初期解の経路
#print "ddd"
    @path = seek_one_path(@path,goal)
#print "nnn"
    #print "eee"
    #突然変異
    #for k in 1.. generation_number
    #  r=rand(@path.length-2)
    #  path_c = seek_one_path(@path[0 .. r+1],goal)
    #  if path_c.length < @min_length then
    #    @path = path_c
    #    @min_length = path_c.length
    #  end
    #end
  end


  def seek_one_path(path_o,goal)
#print "eee"
    path_c = Array.new
    path_c = path_o.dup
#print "fff"
iii=0;
    while 0 < 1 do
iii = iii+1
#次ノードの候補を取得
#print "ggg"
next_nodes = next_node(path_c)
#次ノードの候補がなければ破棄してはじめから。
#print "hhh"
       if next_nodes.length==0 then
         path_c = path_o.dup
#次ノードの候補があれば次ノードへ進める
      else
#print "iii"
#print "nextnodeslength="
#print next_nodes.length

        node_i = next_nodes[rand(next_nodes.length)]



#iiii=0
#while iiii <10000000 do
#iiii = iiii+1
#end
#print "rand="
#print rand(next_nodes.length)
        path_c.push(node_i)

#print path_c
#print "----------------------------------------------"

#ゴールノードなら終了。
#print "jjj"
#print node_i
#print "kkk"
#print goal
goal_node=@all.select { |n| n.name == goal }

#print "ttesr=="
#print node_i.name
#print"test=="
#print goal_node

        if(node_i.name == goal) then
#          print "mmm"
          break
        end
      end
    end
    return path_c
  end


  def next_node(path_c)
#print "gg1"
#print "path_c.last"
#print path_c.last
#print "gg2"
#last_node=@all.select { |n| n.name == path_c.last }
last_node = path_c.last
#print "gg4"
#print "lasnode"
#print last_node
#print "gg3"
#print last_node
#neighbors = Array.new
#neighbors = last_node.name
#print last_node
#print neighbors
#print "aa"
#print last_node.name
#print last_node.neighbors
next_nodes = Array.new

    last_node.neighbors.each do |each|
#print "g2"
#print each
      if path_c.include?(find(each, @all))==false then
#print "g3"
#print find(each, @all)
        next_nodes.push(find(each, @all))
#print "g3.5"
      end
#print "g4"
    end
    return next_nodes
  end

end
