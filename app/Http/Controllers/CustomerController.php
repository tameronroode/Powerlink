<?php

namespace App\Http\Controllers;
use App\Http\Requests\StoreCustomerRequest;

use App\Models\Customer;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function index()
    {
        return Customer::withCount(['interactions', 'serviceTickets'])->latest()->paginate(20);
    }

    public function store(StoreCustomerRequest $req)
    {
        $c = Customer::create($req->validated());
        return response()->json($c, 201);
    }

    public function show(Customer $customer)
    {
        return $customer->load(['interactions.employee', 'serviceTickets']);
    }

    public function update(StoreCustomerRequest $req, Customer $customer)
    {
        $customer->update($req->validated());
        return $customer;
    }

    public function destroy(Customer $customer)
    {
        $customer->delete();
        return ['ok' => true];
    }
}

