require 'spec_helper'

describe "sys_users", type: :feature, dbscope: :example do
  let(:item) { create(:sys_role) }
  let(:index_path) { sys_roles_path }
  let(:new_path) { new_sys_role_path }
  let(:show_path) { sys_role_path item }
  let(:edit_path) { edit_sys_role_path item }
  let(:delete_path) { delete_sys_role_path item }

  context "with auth" do
    before { login_sys_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        check "item_permissions_edit_sys_sites"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end
end
