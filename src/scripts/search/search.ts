import { serchCategory } from "./api";
import { initializeServiceClient, intializeIndexClient } from "./client";

const isLocal = true;
const indexClient = intializeIndexClient(isLocal);
const serviceClient = initializeServiceClient(isLocal, indexClient);

async function serchCategoryByBlog() {
  let result = await serchCategory(serviceClient, "test", "blog")
  console.log(result)
}

// serchCategoryByBlog() 