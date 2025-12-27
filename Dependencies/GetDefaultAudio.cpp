#include <windows.h>
#include <mmdeviceapi.h>
#include <endpointvolume.h>
#include <functiondiscoverykeys_devpkey.h>
#include <iostream>
#include <comdef.h>

void PrintDefaultDevice(EDataFlow flow, ERole role) {
    IMMDeviceEnumerator* pEnum = nullptr;
    IMMDevice* pDevice = nullptr;
    IPropertyStore* pProps = nullptr;

    CoInitialize(nullptr);
    CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                     __uuidof(IMMDeviceEnumerator), (void**)&pEnum);

    if (pEnum) {
        if (SUCCEEDED(pEnum->GetDefaultAudioEndpoint(flow, role, &pDevice))) {
            if (SUCCEEDED(pDevice->OpenPropertyStore(STGM_READ, &pProps))) {
                PROPVARIANT varName;
                PropVariantInit(&varName);
                if (SUCCEEDED(pProps->GetValue(PKEY_Device_FriendlyName, &varName))) {
                    std::wcout << varName.pwszVal;
                }
                PropVariantClear(&varName);
                pProps->Release();
            }
            pDevice->Release();
        }
        pEnum->Release();
    }

    CoUninitialize();
}

int wmain() {
    // Default playback device
    PrintDefaultDevice(eRender, eConsole);
    std::wcout << L"\n";
    // Default communications device
    PrintDefaultDevice(eRender, eCommunications);
    std::wcout << L"\n";
    return 0;
}
