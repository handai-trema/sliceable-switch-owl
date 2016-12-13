#require 'vis'
require 'pio'
require 'topology'

module View
  # Topology controller's GUI (vis).
  class VisJs

    def initialize(output = 'vendor/topology/lib/view/')
      @output = output + 'topology.txt'
      @output2 = output + 'watched/path.txt'
    end

    def update(_event, _changed, topology)

      @linkList = Array.new
      count=100000
      
      # write node data
      File.open(@output, "w") do |file|
        
        #switch
        nodes = topology.switches.each_with_object({}) do |each, tmp|
          file.printf("%d Switch:%d\n",each.to_i, each.to_i)
        end
        #host and slice
        file.printf("host\n")
        topology.hosts.each do |each|  #for all host
          slice_info = getSliceInfo(topology, each[0].to_s)
          file.printf("%s Host:%s %s\n",each[0].to_s, each[0].to_s, slice_info)
        end

        @temp = Hash.new {[]}#check link
        #link of switches
        file.printf("link\n")
        topology.links.each do |each|
          if checkLinkList(@temp,each.dpid_a.to_i,each.dpid_b.to_i )==true then
            file.printf("%d %d %d\n",count, each.dpid_a.to_i, each.dpid_b.to_i)
            @temp[each.dpid_a.to_i].push(each.dpid_b.to_i)
            @linkList. << [count, each.dpid_a.to_s, each.dpid_b.to_s]
            count = count + 1
          end
        end
        #link between host and switch
        topology.hosts.each do |each|  #for all host
          if checkLinkList(@temp,each[0].to_s,each[2].to_i )==true then
            file.printf("%d %s %d\n",count, each[0].to_s, each[2].to_i)
            @temp[each[0].to_s].push(each[2].to_i)
            @linkList << [count, each[0].to_s, each[2].to_s]
            count = count + 1
          end
        end

      end


      File.open(@output2, "w") do |file|
         #paths
        topology.paths.each do |eachPath|  #for all paths
          for n_num in 0..eachPath.count-2 do
            id = checkLinkID(@linkList, eachPath[n_num], eachPath[n_num+1])
            file.printf("%s ",id)
          end
          file.printf("\n")
        end
      end
      
    end

    private
    
    def checkLinkList(getList, a, b)
      getList.each_key do |key|
        getList[key].each do |each|
          if (each == a && key==b) || (each == b && key==a) then
            return false
          end
        end
      end
      return true
    end

    def checkLinkID(getList, a, b)
      count_temp=0
      getList.each do|each_a, each_b, each_c|
        if(each_b==a && each_c==b) || (each_b==b && each_c==a) then
          return each_a
        end
        count_temp = count_temp + 1
      end
      print "false\n"
    end

    def getSliceInfo(topology, hostName)
      #print hostName + " for debug slice info \n"
      topology.slices.each do |each_slice|
        each_slice.each do |name, each_port|
          each_port.each do |each|
            if each == hostName
              return each_slice.to_s
            end
          end
        end
      end
    end
    
  end
end
