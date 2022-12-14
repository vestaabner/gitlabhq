# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for code' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  context 'when signed in' do
    before do
      stub_feature_flags(search_page_vertical_nav: false)
      project.add_maintainer(user)
      sign_in(user)
    end

    it 'finds a file' do
      visit(project_path(project))

      submit_search('application.js')
      select_search_scope('Code')

      expect(page).to have_selector('.results', text: 'application.js')
      expect(page).to have_selector('.file-content .code')
      expect(page).to have_selector("span.line[lang='javascript']")
      expect(page).to have_link('application.js', href: %r{master/files/js/application.js})
      expect(page).to have_button('Copy file path')
    end

    context 'when on a project page', :js do
      before do
        visit(search_path)
        find('[data-testid="project-filter"]').click

        wait_for_requests

        page.within('[data-testid="project-filter"]') do
          click_on(project.name)
        end
      end

      include_examples 'top right search form'
      include_examples 'search timeouts', 'blobs'

      it 'finds code and links to blob' do
        fill_in('dashboard_search', with: 'rspec')
        find('.gl-search-box-by-click-search-button').click

        expect(page).to have_selector('.results', text: 'Update capybara, rspec-rails, poltergeist to recent versions')

        find("#blob-L3").click
        expect(current_url).to match(%r{blob/master/.gitignore#L3})
      end

      it 'finds code and links to blame' do
        fill_in('dashboard_search', with: 'rspec')
        find('.gl-search-box-by-click-search-button').click

        expect(page).to have_selector('.results', text: 'Update capybara, rspec-rails, poltergeist to recent versions')

        find("#blame-L3").click
        expect(current_url).to match(%r{blame/master/.gitignore#L3})
      end

      it 'search mutiple words with refs switching' do
        expected_result = 'Use `snake_case` for naming files'
        search = 'for naming files'

        fill_in('dashboard_search', with: search)
        find('.gl-search-box-by-click-search-button').click

        expect(page).to have_selector('.results', text: expected_result)

        find('.ref-selector').click
        wait_for_requests

        page.within('.ref-selector') do
          find('li', text: 'v1.0.0').click
        end

        expect(page).to have_selector('.results', text: expected_result)

        expect(find_field('dashboard_search').value).to eq(search)
        expect(find("#blob-L1502")[:href]).to match(%r{blob/v1.0.0/files/markdown/ruby-style-guide.md#L1502})
        expect(find("#blame-L1502")[:href]).to match(%r{blame/v1.0.0/files/markdown/ruby-style-guide.md#L1502})
      end
    end

    context 'when :new_header_search is true' do
      context 'search code within refs', :js do
        let(:ref_name) { 'v1.0.0' }

        before do
          # This feature is diabled by default in spec_helper.rb.
          # We missed a feature breaking bug, so to prevent this regression, testing both scenarios for this spec.
          # This can be removed as part of closing https://gitlab.com/gitlab-org/gitlab/-/issues/339348.
          stub_feature_flags(new_header_search: true)
          visit(project_tree_path(project, ref_name))

          submit_search('gitlab-grack')
          select_search_scope('Code')
        end

        it 'shows ref switcher in code result summary' do
          expect(find('.ref-selector')).to have_text(ref_name)
        end

        it 'persists branch name across search' do
          find('.gl-search-box-by-click-search-button').click
          expect(find('.ref-selector')).to have_text(ref_name)
        end

        #  this example is use to test the desgine that the refs is not
        #  only repersent the branch as well as the tags.
        it 'ref swither list all the branchs and tags' do
          find('.ref-selector').click
          wait_for_requests

          page.within('.ref-selector') do
            expect(page).to have_selector('li', text: 'add-ipython-files')
            expect(page).to have_selector('li', text: 'v1.0.0')
          end
        end

        it 'search result changes when refs switched' do
          ref = 'master'
          expect(find('.results')).not_to have_content('path = gitlab-grack')

          find('.ref-selector').click
          wait_for_requests

          page.within('.ref-selector') do
            fill_in _('Search by Git revision'), with: ref
            wait_for_requests

            find('li', text: ref).click
          end

          expect(page).to have_selector('.results', text: 'path = gitlab-grack')
        end
      end
    end

    context 'when :new_header_search is false' do
      context 'search code within refs', :js do
        let(:ref_name) { 'v1.0.0' }

        before do
          # This feature is diabled by default in spec_helper.rb.
          # We missed a feature breaking bug, so to prevent this regression, testing both scenarios for this spec.
          # This can be removed as part of closing https://gitlab.com/gitlab-org/gitlab/-/issues/339348.
          stub_feature_flags(new_header_search: false)
          visit(project_tree_path(project, ref_name))

          submit_search('gitlab-grack')
          select_search_scope('Code')
        end

        it 'shows ref switcher in code result summary' do
          expect(find('.ref-selector')).to have_text(ref_name)
        end

        it 'persists branch name across search' do
          find('.gl-search-box-by-click-search-button').click
          expect(find('.ref-selector')).to have_text(ref_name)
        end

        #  this example is use to test the desgine that the refs is not
        #  only repersent the branch as well as the tags.
        it 'ref swither list all the branchs and tags' do
          find('.ref-selector').click
          wait_for_requests

          page.within('.ref-selector') do
            expect(page).to have_selector('li', text: 'add-ipython-files')
            expect(page).to have_selector('li', text: 'v1.0.0')
          end
        end

        it 'search result changes when refs switched' do
          ref = 'master'
          expect(find('.results')).not_to have_content('path = gitlab-grack')

          find('.ref-selector').click
          wait_for_requests

          page.within('.ref-selector') do
            fill_in _('Search by Git revision'), with: ref
            wait_for_requests

            find('li', text: ref).click
          end

          expect(page).to have_selector('.results', text: 'path = gitlab-grack')
        end
      end
    end

    it 'no ref switcher shown in issue result summary', :js do
      issue = create(:issue, title: 'test', project: project)
      visit(project_tree_path(project))

      submit_search('test')
      select_search_scope('Code')

      expect(page).to have_selector('.ref-selector')

      select_search_scope('Issues')

      expect(find(:css, '.results')).to have_link(issue.title)
      expect(page).not_to have_selector('.ref-selector')
    end
  end

  context 'when signed out' do
    let(:project) { create(:project, :public, :repository) }

    before do
      stub_feature_flags(search_page_vertical_nav: false)
      visit(project_path(project))
    end

    it 'finds code' do
      submit_search('rspec')
      select_search_scope('Code')

      expect(page).to have_selector('.results', text: 'Update capybara, rspec-rails, poltergeist to recent versions')
    end
  end
end
