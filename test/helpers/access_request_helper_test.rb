require_relative '../test_helper'

describe AccessRequestHelper do
  include AccessRequestTestSupport
  describe '#display_access_request_link?' do
    before { enable_access_request }
    after { restore_access_request_settings }

    describe 'feature enabled' do
      it 'returns true for authorization_error' do
        assert(display_access_request_link? :authorization_error)
      end

      it 'returns false for other flash types' do
        refute(display_access_request_link? :success)
      end
    end

    describe 'feature disabled' do
      before { ENV['REQUEST_ACCESS_FEATURE'] = nil }

      it 'returns false for all flash types' do
        refute(display_access_request_link? :authorization_error)
        refute(display_access_request_link? :success)
      end
    end
  end

  describe '#link_to_request_access' do
    let(:current_user) { users(:viewer) }
    let(:matcher) { /<a href="\/access_requests\/new">.*<\/a>/ }

    it 'shows a link if there is no request pending' do
      current_user.update!(access_request_pending: false)
      assert_match(matcher, link_to_request_access)
    end

    it 'does not show a link if a request is pending' do
      current_user.update!(access_request_pending: true)
      refute_match(matcher, link_to_request_access)
    end
  end
end
