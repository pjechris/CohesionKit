import CohesionKit

class LoggerMock: Logger {
    var didStoreCalled: ((type: Any.Type, id: Any)) -> () = { _ in }

    func didStore<T>(_ type: T.Type, id: T.ID) where T : Identifiable {
        didStoreCalled((type, id))
    }

    func didFailedToStore<T>(_ type: T.Type, id: T.ID, error: Error) where T : Identifiable {
        
    }

    func didRegisterAlias<T>(_ alias: CohesionKit.AliasKey<T>) {
        
    }

    func didUnregisterAlias<T>(_ alias: CohesionKit.AliasKey<T>) {
        
    }
}