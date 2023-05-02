import { ActorClient } from "candb-client-typescript/dist/ActorClient";
import { Service } from "../../declarations/candb_service/candb_service.did";
import { IndexCanister } from "../../declarations/candb_index/candb_index.did";

// export async function get_all_keys_for_test(serviceClient: ActorClient<IndexCanister, Service>, pk: string) {
//   let queryResults = await serviceClient.query<Service["get_all_keys_for_test"]>(
//     pk,
//     (actor) => actor.get_all_keys_for_test()
//   );

//   return queryResults

//   // for (let settledResult of userGreetingQueryResults) {
//   //   // handle settled result if fulfilled
//   //   if (settledResult.status === "fulfilled" && settledResult.value.length > 0) {
//   //     // handle candid returned optional type (string[] or string)
//   //     return Array.isArray(settledResult.value) ? settledResult.value[0] : settledResult.value
//   //   } 
//   // }
  
//   // return "User does not exist";
// };


export async function serchCategory(serviceClient: ActorClient<IndexCanister, Service>, pk: string, category: string) {
  let queryResults = await serviceClient.query<Service["searchCategory"]>(
    pk,
    (actor) => actor.searchCategory(category, [])
  );

  for (let settledResult of queryResults) {
    // handle settled result if fulfilled
    if (settledResult.status === "fulfilled" && settledResult.value.length > 0) {
      // handle candid returned optional type (string[] or string)
      return Array.isArray(settledResult.value) ? settledResult.value[0] : settledResult.value
    } 
  }

  return queryResults
};