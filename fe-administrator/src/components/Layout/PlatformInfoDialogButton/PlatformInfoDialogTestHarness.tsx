import { useEffect } from 'react';
import { actions as infoActions } from 'ducks/info';
import PlatformInfoDialogLink from './index';
import { useRecordingStore, withProviders } from 'utils/test-helpers';

const mockPlatformInfo = {
    app: { name: 'Core', version: '2.16.4-SNAPSHOT' },
    db: { system: 'PostgreSQL', version: '15.6' },
    builder: 'Test Builder',
};

const preloadedState = {
    info: { platformInfo: mockPlatformInfo, isFetching: false },
};

const PlatformInfoDialogTestHarness = () => {
    const { store } = useRecordingStore(preloadedState, 'info/');

    useEffect(() => {
        store.dispatch(infoActions.getPlatformInfoSuccess(mockPlatformInfo));
    }, [store]);

    return withProviders(<PlatformInfoDialogLink forceOpen={true} />, { store });
};

export default PlatformInfoDialogTestHarness;
