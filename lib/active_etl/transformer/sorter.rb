module ActiveETL
  module Transformer
    class Sorter
      attr_reader :tsorted_nodes

      def initialize(tree)
        @tree = tree
        @tsorted_nodes = tree.tsort
      end
  
      def dependencies(node)
        @tree[node]
      end
  
      def node_def(node)
        @tree.select{|k, v| k == node}
      end
  
      def dependents(node)
        r = []
        @tree.each do |k, v|
          r << k if v.include?(node)
        end
        r.uniq
      end
  
      def standalone_nodes
        @standalone_nodes ||= tsorted_nodes.select{|m| dependencies(m) == [] && dependents(m) == []}
      end
  
      def chainable_nodes
        @chainable_nodes ||= tsorted_nodes - standalone_nodes
      end

      def chains
        nodes = chainable_nodes.dup
        result = chain_for(nodes)
        standalone_nodes.reverse.each{|node| result.unshift [node]}
        result
      end
  
      def full_dependencies(node, accumulator = [])
        dependencies(node).each do |node|
          full_dependencies(node, accumulator)
        end
        accumulator << node
      end
  
      private
      def chain_for(nodes, accumulator = [])
        unless nodes == []
          node = nodes.pop
          d = full_dependencies(node)
          accumulator << d
          chain_for(nodes - d, accumulator)
        else
          accumulator
        end
      end
    end
  end
end
