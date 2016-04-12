module Projects
  module ImportExport
    class ProjectTreeRestorer
      attr_reader :project

      def initialize(path:, user:)
        @path = path
        @user = user
      end

      def restore
        json = IO.read(@path)
        @tree_hash = ActiveSupport::JSON.decode(json)
        @project_members = @tree_hash.delete('project_members')
        create_relations
      end

      private

      def members_map
        @members ||= Projects::ImportExport::MembersMapper.map(
          exported_members: @project_members, user: @user, project_id: project.id)
      end

      def create_relations(relation_list = default_relation_list, tree_hash = @tree_hash)
        relation_list.each do |relation|
          if relation.is_a?(Hash)
            create_sub_relations(relation, tree_hash)
          end
          relation_key = relation.is_a?(Hash) ? relation.keys.first : relation
          relation_hash = create_relation(relation_key, tree_hash[relation_key.to_s])
          project.update_attribute(relation_key, relation_hash)
          # FIXME
          # next if tree_hash[relation.to_s].blank?
        end
      end

      def default_relation_list
        Projects::ImportExport::ImportExportReader.tree.reject { |model| model.is_a?(Hash) && model[:project_members] }
      end

      def project
        @project ||= create_project
      end

      def create_project
        project_params = @tree_hash.reject { |_key, value| value.is_a?(Array) }
        project = Projects::ImportExport::ProjectFactory.create(
          project_params: project_params, user: @user)
        project.save
        project
      end

      def create_sub_relations(relation, tree_hash)
        tree_hash[relation.keys.first.to_s].each do |relation_item|
          relation.values.flatten.each do |sub_relation|
            relation_hash = relation_item[sub_relation.to_s]
            next if relation_hash.blank?
            sub_relation_object = relation_from_factory(relation, relation_hash)
            relation_item[sub_relation.to_s] = sub_relation_object
          end
        end
      end

      def create_relation(relation, relation_hash_list)
        [relation_hash_list].flatten.map do |relation_hash|
          relation_from_factory(relation, relation_hash)
        end
      end

      def relation_from_factory(relation, relation_hash)
        Projects::ImportExport::RelationFactory.create(
          relation_sym: relation, relation_hash: relation_hash.merge('project_id' => project.id), members_map: members_map)
      end
    end
  end
end
