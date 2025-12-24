#include <cmath>
#include <memory>
#include <optional>
#include <string>
#define NOMINMAX
#include <Windows.h>
#include <algorithm>
#include <cstdio>

#include "uevr/Plugin.hpp"

using namespace uevr;

class CutscenePlugin : public uevr::Plugin {
public:
    CutscenePlugin() = default;

    void on_pre_engine_tick(API::UGameEngine* engine, float delta) override {
        try {
            update_cutscene_status();
        } catch (const std::exception& e) {
            API::get()->log_error("[CutscenePlugin] Exception in on_pre_engine_tick: %s", e.what());
        } catch (...) {
            API::get()->log_error("[CutscenePlugin] Unknown exception in on_pre_engine_tick");
        }
    }

private:
    void update_cutscene_status() {
        auto& api = API::get();

        auto pc = api->get_player_controller(0);

        if (pc == nullptr) {
            set_cutscene_status(false);
            return;
        }

        auto pcm_ptr = pc->get_property_data<API::UObject*>(L"PlayerCameraManager");
        auto pcm = pcm_ptr ? *pcm_ptr : nullptr;

        if (pcm == nullptr) {
            set_cutscene_status(false);
            return;
        }

        struct ViewTargetStruct {
            API::UObject* Target;
        };

        auto vt = pcm->get_property_data<ViewTargetStruct>(L"ViewTarget");

        if (vt == nullptr || vt->Target == nullptr) {
            set_cutscene_status(false);
            return;
        }

        static auto cine_class = api->find_uobject<API::UClass>(L"Class /Script/CinematicCamera.CineCameraActor");

        if (cine_class == nullptr) {
            set_cutscene_status(false);
            return;
        }

        bool is_cutscene = vt->Target->is_a(cine_class);
        set_cutscene_status(is_cutscene);
    }

    void set_cutscene_status(bool in_cutscene) {
        if (m_in_cutscene != in_cutscene) {
            m_in_cutscene = in_cutscene;
            API::UObjectHook::set_disabled(in_cutscene);

            if (in_cutscene) {
                handle_cutscene_start();
            } else {
                handle_cutscene_end();
            }
        }
    }

    void handle_cutscene_start() {
        m_original_aim_method = uevr::API::VR::get_aim_method();
        uevr::API::VR::set_aim_method(uevr::API::VR::AimMethod::GAME);
        uevr::API::VR::recenter_view();
    }

    void handle_cutscene_end() { uevr::API::VR::set_aim_method(m_original_aim_method); }

    void reset_status() { m_in_cutscene = false; }

private:
    bool m_in_cutscene{false};
    uevr::API::VR::AimMethod m_original_aim_method{uevr::API::VR::AimMethod::GAME};
};

std::unique_ptr<CutscenePlugin> g_plugin{std::make_unique<CutscenePlugin>()};